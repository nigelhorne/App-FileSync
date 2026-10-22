# App::FileSync

A cron/CLI file synchroniser: clients keep a directory in step with a master copy on a
server, and a second machine can hold a replica of that master.

All sync logic is Perl. There is no daemon, no web application, no database server and no
rsync: a run is a short-lived process that talks to `filesync-server` over one connection —
a pipe for the local transport, one `ssh` process for the ssh transport. The ssh command
line is built as an argument list and never passed through a shell.

The design is in [SPEC.md](SPEC.md).

## Status

Phases 1–3 are implemented: merge engine, scan/hash cache, ignore patterns, local and SSH
transports, the forced-command server, host key checking, per-run locking, the server
journal, push/pull/delete with trash, conflict copies, the replica mirror with snapshots,
and `verify` and `restore` on both the client and `filesync-admin`. Diagnostics go through
Log::Abstraction and process settings through Object::Configure.

## Server setup

```sh
sudo useradd --system --create-home filesync
sudo -u filesync filesync-admin repo create documents
sudo -u filesync filesync-admin client allow laptop-1 --role client
sudo -u filesync filesync-admin client allow backup-1 --role replica
```

Then give the client key an entry in `~filesync/.ssh/authorized_keys` that pins the session:

```
restrict,command="filesync-server --repo documents --client laptop-1 --role client" ssh-ed25519 AAAA... laptop-1
```

`restrict` turns off pty, forwarding, agent and X11. The pinned `--repo`, `--client` and
`--role` are the authority: the server compares them with the session's `hello` and with
`SSH_ORIGINAL_COMMAND`, and refuses anything that asks for a different repo, client, role
or root. The server's root comes from the forced command or `FILESYNC_ROOT`, defaulting to
`/srv/filesync` — the client never sends it.

## Client setup

```sh
filesync init --repo documents --root ~/Documents \
    --server filesync@files.example.com --remote-repo documents --id laptop-1

filesync sync --repo documents --dry-run
filesync sync --repo documents
```

Cron:

```
*/15 * * * * /usr/local/bin/filesync sync --quiet >> ~/.filesync/logs/cron.log 2>&1
```

Host keys are checked strictly by default. `--accept-host-key` records `accept-new` for that
repo (trust on first use, refuse any later change); `--known-hosts FILE` keeps the entries in
a private file; `--server-command PATH` names the remote program. Batch mode is always on, so
a missing key fails the run instead of prompting. The key, known-hosts file and remote
program are usually set once for the machine in the settings file (see below) rather than
per repo; the `filesync init` flags then only record an exception.

## Replica and snapshots

A replica is a second machine that holds an exact mirror of the master. It is pull-only:
the server gives it a plan with no writes in it, and refuses a `put`, `mkdir` or `del` even
if one is sent by hand.

```sh
filesync init --repo documents --root /backup/documents \
    --server filesync@files.example.com --remote-repo documents \
    --id backup-1 --role replica

filesync snapshot --repo documents --keep 14
filesync sync --repo documents
```

Cron on the backup host — snapshot first, so a bad sync can be rolled back:

```
0 2 * * * /usr/local/bin/filesync snapshot --repo documents --keep 14
30 2 * * * /usr/local/bin/filesync sync --repo documents --quiet
```

Snapshots live in `<root>/.filesync-snapshots/YYYY-MM-DD/` and share their files with the
mirror through hardlinks on Unix (a copy on Windows, or with `--snapshot-mode copy` at
`init`). That makes them nearly free in disk space and time. Two consequences:

- Hardlinks share the inode, so editing a mirrored file *in place* also changes every
  snapshot holding it. The syncer always replaces files rather than writing through them,
  so this only matters if something else edits the replica root. Use copy mode if that is
  a real risk.
- The `.filesync-snapshots` directory is on the shared ignore list, so it is never mistaken
  for a local extra and deleted by the mirror.

The first snapshot of a day is kept; running `filesync snapshot` again the same day reports
that it already exists rather than overwriting the older state. `--keep N` keeps the N
newest days and removes the rest; the default is 14 (`--keep` per run, or `snapshot_keep`
in the repo's client config).

To roll a damaged mirror back:

```sh
filesync snapshot list --repo documents
filesync snapshot restore 2026-10-21 --repo documents              # into the mirror root
filesync snapshot restore 2026-10-21 notes/report.txt --to /tmp/old   # or export it
```

Restoring copies the snapshot's files over the target and replaces files that already
exist; files added since the snapshot are left alone, so this recovers versions rather than
rewinding the directory. Because a replica is pull-only, the next `filesync sync` mirrors
the master again — that is the point when the master is also fixed, but use `--to DIR` if
you want to keep the old version instead.

## Verify

`filesync verify` compares the local tree with the cached base from the last successful
sync and reports what has drifted since:

```
docs: drift detected (412 files, 3 rehashed, 409 unchanged)
  modified: notes/report.txt
  missing:  notes/old.txt
  extra:    notes/draft.txt
```

It exits **4** when it finds drift, so a cron job can mail it. Files whose size and mtime
still match are trusted from the cache; `--deep` rehashes everything, and `--json` prints
the report for another program.

`filesync log` is the audit trail behind that: every attempt appends its exit code, counts
and warnings to `~/.filesync/logs/<repo>.jsonl` (the newest 500 are kept), so a conflict that
happened overnight can be understood offline. Dry runs are recorded too and marked as such.
A run that failed records `exit 1` and the error; one refused because the lock was already
held (here or on the server) records `exit 2`, a `locked` flag and the reason. The trail
therefore shows everything cron tried, not only the runs that finished.

`--since YYYY-MM-DD` (or an epoch) starts the window; `--until` ends it, and a date there
means the whole of that day. `--exit N` keeps only runs with that exit code and can be
repeated, so `--exit 1 --exit 3` lists the failures and conflicts without the quiet runs.
Filters are applied before `-n`, and `--json` prints the same records for another program,
mirroring `verify`: one result per repo, each with its file and run list, plus the echoed
`since`, `until` and `exits` when given. Failures and lock refusals appear there with their
`error` (and `locked` for a refusal). A repo that has not run yet appears with an empty list.

```
$ filesync log --repo documents -n 3
documents  20261022T180132Z  exit 0  pulled 0, pushed 2, deleted 0, conflicts 0
documents  20261022T181507Z  exit 0  pulled 0, pushed 0, deleted 0, conflicts 0
documents  20261022T183002Z  exit 3  pulled 0, pushed 1, deleted 0, conflicts 1
  warning: notes/report.txt: changed on both laptop-1 and the master; master version kept, laptop-1 version saved as notes/report.conflict-laptop-1-20261022T183002Z.txt
```

```sh
# what failed or conflicted since Monday, as data
filesync log --since 2026-10-19 --exit 1 --exit 3 --json \
  | jq '.results[].runs[] | select(.exit != 0)'
```

```json
{"results":[{"repo":"documents","path":"/home/me/.filesync/logs/documents.jsonl",
             "since":1792454400,"runs":[{"ts":1792696202,"exit":0,
             "summary":{"pulled":0,"pushed":2,"deleted":0,"conflicts":0,"skipped":0},
             "warnings":[],"dry_run":0}]}]}
```

On the server, `filesync-admin verify NAME` rehashes the master against its index and
reports `missing`, `extra` and `modified` in the same way. `--sample N` rehashes N matching
files at random, and `--deep` rehashes the lot:

```sh
filesync-admin --root /srv/filesync verify documents
filesync-admin --root /srv/filesync verify documents --sample 50
```

## Restore

Deletions are recoverable from the trash on either side.

```sh
# client: from ~/.filesync/trash, back into the sync root
filesync restore notes/report.txt --repo documents
filesync restore notes/report.txt --repo documents --list
filesync restore notes/report.txt --repo documents --to /tmp/export

# server: from the repo trash, back into the master (or an export)
filesync-admin --root /srv/filesync restore documents notes/report.txt
filesync-admin --root /srv/filesync restore documents notes/report.txt --list
filesync-admin --root /srv/filesync restore documents notes/report.txt --to /tmp/export
filesync-admin --root /srv/filesync restore documents notes/report.txt --date 2026-10-21
```

`restore` refuses to overwrite an existing path — move it aside first. The trash entry is
copied rather than moved, so the same version can be restored again. Restoring on the
server rebuilds the index for the master, so `filesync-admin verify` is clean immediately,
and the next client run pulls the restored file. Every server restore is written to the
journal.

## Commands

```
filesync init --repo NAME --root DIR --server USER@HOST [--remote-repo NAME] [--id ID]
              [--role client|replica] [--port N] [--identity FILE]
              [--accept-host-key] [--known-hosts FILE] [--server-command PATH]
              [--snapshot-mode hardlink|copy]
filesync init --repo NAME --root DIR --transport local --server-root DIR
filesync sync [--repo NAME]... [--dry-run] [--force] [--verbose] [--quiet] [--json]
filesync status [--repo NAME] [--json]
filesync log [--repo NAME] [-n N] [--since YYYY-MM-DD|EPOCH] [--until YYYY-MM-DD|EPOCH]
             [--exit N]... [--json]
filesync verify [--repo NAME] [--deep] [--json]
filesync restore PATH [--repo NAME] [--to DIR] [--list]
filesync snapshot [--repo NAME] [--keep N]
filesync snapshot list [--repo NAME]
filesync snapshot restore DATE [PATH] [--repo NAME] [--to DIR]
filesync version

filesync-admin --root DIR repo create NAME [--trash-days N] [--max-deletes N]
filesync-admin --root DIR repo list | repo show NAME
filesync-admin --root DIR client allow ID --repo NAME [--role client|replica]
filesync-admin --root DIR client list --repo NAME
filesync-admin --root DIR client forget ID --repo NAME
filesync-admin --root DIR verify NAME [--deep] [--sample N] [--json]
filesync-admin --root DIR restore NAME PATH [--to DIR] [--list] [--date YYYY-MM-DD]
filesync-admin --root DIR log NAME [-n N] [--client ID] [--since YYYY-MM-DD|EPOCH]
```

Exit codes: `0` success, `1` fatal, `2` another run holds the lock, `3` completed with
warnings (conflicts, skipped files), `4` verification found drift.

## Logging and settings

Diagnostics go through [Log::Abstraction](https://metacpan.org/pod/Log::Abstraction);
command results (summaries, plans, `--json`) stay on standard output, so a cron job can keep
the two apart. By default warnings and errors are written to standard error as
`WARN: …` / `ERROR: …`, which includes a session the server refused.

Process-wide settings come from
[Object::Configure](https://metacpan.org/pod/Object::Configure):
`~/.conf/app-filesync.json`, or the file named by `$FILESYNC_SETTINGS`, with
`App__FileSync__*` environment variables overriding it:

```json
{
  "App__FileSync": {
    "log_level": "debug",
    "log_format": "%level%: %message%",
    "log_file": "/home/njh/.filesync/logs/filesync.log",
    "ssh_identity": "~/.ssh/filesync_ed25519",
    "ssh_known_hosts": "~/.ssh/filesync_known_hosts",
    "server_command": "/usr/local/bin/filesync-server"
  }
}
```

`log_level` is `trace`, `debug`, `info`, `notice`, `warning` (the default), `error`,
`crit`, `alert` or `emerg`. `log_format` is a Log::Abstraction format. `log_file` sends
the log to a file instead of standard error and creates its directory. A `UNIVERSAL`
section in the same directory applies to every class that uses Object::Configure.

`ssh_identity`, `ssh_known_hosts` and `server_command` are the SSH defaults for every
repo, so the same key and remote program do not have to be repeated in each `filesync
init`. `server_command` defaults to `filesync-server`. A value recorded per repo by
`filesync init --identity`, `--known-hosts` or `--server-command` still wins, which is
how one repo can use a different key from the rest.

```
App__FileSync__log_level=debug filesync sync --quiet
```

The repo definitions are not in this file: they stay in `~/.filesync/config.json`, which
`filesync init` writes and `filesync-admin` edits. `--verbose` raises the level to `debug`
for that run and `--quiet` lowers it to `error`; either flag beats the settings file.

## Journal

Every session writes JSON lines to `<repo>/journal/YYYY-MM.jsonl`: the plan, each push,
delete and mkdir, each conflict with both hashes, both mtimes, the winner and the name of
the preserved copy, the session summary, and admin restores. Dry runs write nothing.
`filesync-admin log` reads it back, newest last:

```
20261022T185056Z  laptop-1     delete       report.txt trash=/srv/filesync/.../trash/2026/10/22/report.txt
20261022T185056Z  laptop-1     session      conflicts=0 pulled=0 pushed=0 deleted=1
20261022T185056Z  -            restore      report.txt trash=/srv/filesync/.../trash/2026/10/22/report.txt sha256=8a3c67…
```

## Test

```sh
perl Makefile.PL && make test
# or
prove -l t
```

The suite runs everything through real subprocesses. The ssh tests use a fake `ssh` that
records its arguments and runs `filesync-server` locally, so no sshd or network is needed.

## Licence

GPL v2 for personal single-user, single-computer use; other users must apply for a licence.
See LICENSE.
