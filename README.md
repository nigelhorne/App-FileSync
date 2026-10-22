## Name

App::FileSync - cron-driven file synchronisation without a daemon

## Synopsis

```
filesync init --repo documents --root ~/Documents \
    --transport local --server-root /srv/filesync --remote-repo documents
filesync sync --repo documents --dry-run
filesync sync --repo documents
```

## Description

App::FileSync keeps one directory per client in step with a master copy on a server, and
keeps a separate machine holding a replica of that master.  Every run is a short-lived CLI
process suitable for cron or the Windows Task Scheduler: there is no daemon, no database
and no web interface.

The design and its rationale are in `SPEC.md` in the distribution root.

This module holds the pieces shared by the client, the server and the admin tools:
byte-transparent JSON, path validation, conflict-copy naming and atomic file writes.

## Functions

### Json\_Encode

### Json\_Decode

Encode and decode a structure as a single line of JSON.  Paths are byte strings and are
not treated as UTF-8 by these functions.

### Validate\_Relpath

Returns `(1, undef)` for a safe relative path, or `(0, $reason)`.  Absolute paths,
backslashes, control characters, empty, `.` and `..` components, and paths longer than
4096 bytes or with a component longer than 255 bytes are rejected.

### Validate\_Repo\_Name

### Validate\_Client\_Id

Return `(1, undef)` for a name usable as a directory name (`[A-Za-z0-9][A-Za-z0-9._-]*`,
at most 64 characters), or `(0, $reason)`.

### Conflict\_Name

```perl
my $name = conflict_name('notes.txt', 'laptop-1', time);
```

Returns the conflict-copy name for a losing version: the original name with
`.conflict-<client>-<timestamp>` inserted before the extension.

### Format\_Utc

Formats an epoch as `YYYYMMDDTHHMMSSZ`.

### Write\_Atomic

Writes a file through a temporary file in the same directory and renames it into place.

## Licence

GPL v2 for personal single-user, single-computer use.  All other users must apply in
writing to the author.

## Author

Nigel Horne <njh@nigelhorne.com>
