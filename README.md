# scripts

Personal utility scripts for shell workflows, debugging, reverse engineering, media handling, and small desktop tasks.

## File Index

- [README.md](README.md)
- [DecompileVariables.py](DecompileVariables.py)
- [bgtimer](bgtimer)
- [bootstrap-chroot](bootstrap-chroot)
- [const.py](const.py)
- [cscope-setup](cscope-setup)
- [editplaylist](editplaylist)
- [find_main.py](find_main.py)
- [icebarg.bash](icebarg.bash)
- [newfile.sh](newfile.sh)
- [projects.sh](projects.sh)
- [rattles](rattles)
- [scrape-imgur-album](scrape-imgur-album)
- [slack-closet](slack-closet)
- [snakecase](snakecase)
- [syncp4repo](syncp4repo)
- [tabulate.awk](tabulate.awk)
- [todo](todo)
- [wallpaper.sh](wallpaper.sh)
- [youtube-cli](youtube-cli)
- [yt-cli](yt-cli)

## Files

### [README.md](README.md)

Repository overview and file index for GitHub.

### [DecompileVariables.py](DecompileVariables.py)

Ghidra script that walks the program's `.data` segment, inspects typed data items, and writes C-style variable declarations to `data_variables.c`.

### [bootstrap-chroot](bootstrap-chroot)

Bash utility to bootstrap a chroot by copying selected binaries and their shared libraries, then mounting or unmounting required pseudo-filesystems. When sourced, it also registers shell completion.

Dependencies visible from the script: `bash`, `realpath`, `complete`, `which`, `ldd`, `findmnt`, `mount`, `umount`, `cp`, `mkdir`, `sed`.

### [bgtimer](bgtimer)

Background timer utility. Sourced into a shell, it registers a SIGUSR1 action that runs a command when a timer fires. Run as an executable, it starts a background timer that signals a target shell at a given time or after a delay.

The script determines its name dynamically and can be renamed; functionality remains intact.

Sourced usage:
- `source bgtimer <command>` — register the action and store the command
- `source bgtimer command <cmd>` — change the stored command
- `source bgtimer -p [cmd|-]` — register using a FIFO + SIGWINCH wakeup instead of SIGUSR1; the action runs in a detached reader process, avoiding polling
- `source bgtimer disarm|disable|cancel` — deregister the action
- `source bgtimer help` — show sourced usage

Executable usage:
- `bgtimer <time> <pid>` — fire at an RFC 2822 or ISO 8601 timestamp
- `bgtimer -d <seconds> <pid>` — fire after a number of seconds
- `bgtimer -c <pid>` — cancel a running timer

The command to run on timeout is stored in the `BACKGROUND_TASK_TIMER_CMD` environment variable; `-` selects the default `tput bel`.

Dependencies visible from the script: `bash`, `basename`, `realpath`, `date`, `mkfifo`, `sed`, `trap`, `kill`, `sleep`, `tput`.

### [const.py](const.py)

Tiny Python module that replaces itself with a write-once constant container object.

### [cscope-setup](cscope-setup)

Build helper for C/C++ trees. With `start`, it generates `cscope.files`, then creates a recursive `cscope` database if `cscope` is installed.

### [editplaylist](editplaylist)

Bash utility that adds song entries (title, artist, URL) to a playlist file. With --embed/-e it rewrites only the content between ===playlist=== markers. Without -e the whole file is treated as a plain playlist and reformatted; do not run it without -e on a marked file, since the ===playlist=== markers would be folded into the table as data rows and the marker structure lost (the script now refuses instead). Entries are de-duplicated, sorted, and rendered as a table by [`tabulate.awk`](tabulate.awk). Supports interactive prompts and optional per-file metadata verbosity.

Options: `-p/--playlist`, `-t/--title`, `-a/--artist`, `-u/--url`, `-e/--embed`, `-i/--interactive`, `-v/--verbosity`, `-h/--help`.

Dependencies visible from the script: `bash`, `getopt` (util-linux), `sed`, `sort`, `uniq`, `awk` (GNU), `sponge` (moreutils), plus [`tabulate.awk`](tabulate.awk).

### [find_main.py](find_main.py)

Python script for use inside GDB. It automates locating a program entry point and `main`, and registers helper GDB commands for breakpoints, watchpoints, and stepping to relevant addresses.

### [icebarg.bash](icebarg.bash)

Bash argument parser library built on GNU getopt. Provides `make_optstring` (builds the getopt option string from `name:arg|name:noarg` definitions), `make_optsdesc` (builds a help-text array), `print_usage`, and `parse_opts`. Consuming scripts declare their options via these helpers and set `scriptname`/`scriptdesc` themselves.

Dependencies visible from the script: `bash`, `getopt` (util-linux).

### [newfile.sh](newfile.sh)

Shell function library that creates new files from templates stored under `~/Templates/`, plus tab completion for available template extensions.

Expected environment: source it into an interactive shell so `newfile` and its completion function are available.

### [projects.sh](projects.sh)

Shell function and alias (`prj`) for browsing, creating, templating, and opening projects under `~/Projects`, with completion support for project names, templates, and editors.

Expected environment: source it into an interactive shell.

### [rattles](rattles)

Terminal bell utility. It can either ring a repeating bell at a specific interval or launch several concurrent "rattles" with randomized bell timings.

Dependencies visible from the script: `tput`, `sleep`, `realpath`, `infocmp`, `grep`, `shuf`, `xargs`, `timeout`.

### [scrape-imgur-album](scrape-imgur-album)

Bash script that resolves media URLs from an Imgur album and downloads each item with `curl`. It supports either a supplied Imgur client ID or a built-in API path.

Dependencies visible from the script: `curl`, `python`.

### [slack-closet](slack-closet)

Smol (587 lines, see [other](https://media1.tenor.com/m/CzbOTB8R8OYAAAAd/otters-otter.gif)), over-caffeinated key-value vault built on SQLite; it auto-routes keys into users, channels, messages, or message threads, validates the timestamp keys, uses `jq` to make sure message JASON isn’t lying, and lets you `put`, `get`, `get-all`, `list`, `search`, and `upsert` like a command-line librarian with trust issues. The WAL mode is there so the database can be a bit more concurrency-friendly, and the whole thing behaves like a structured spreadsheet that got a university degree in regex. Does or does not make you more productive, just does not try.

The script sources the shared [`icebarg.bash`](icebarg.bash) argument parser and adds explicit input validation (`check_action`, `check_key`, `check_type`, `check_value`, `check_args`), write/read/delete verification via `check_kv_pairs`, and `jq`-based output formatting (including `-j/--json` raw mode).

Dependencies visible from the script: `bash`, `sqlite3`, `jq`, [`icebarg.bash`](icebarg.bash).


### [snakecase](snakecase)

AWK-driven refactoring helper that rewrites identifiers from camelCase, PascalCase, kebab-case, or Train-Case into `snake_case` inside one or more files. Supports `-b`/`--backup` (keep a `<file>.orig` copy), `-d`/`--debug`, and `-r`/`--release` (strip the debug blocks from the script itself).

Requires GNU awk (`gensub` and array `match`). Output is written to a temp file and only copied over the source when awk succeeds.

Dependencies visible from the script: `awk` (GNU), `realpath`, `sed`, `cp`, `rm`.

### [syncp4repo](syncp4repo)

Python 3 utility for Perforce workflows. It reads command-line arguments or an XML task file, logs activity, and runs `p4 sync` or `p4 opened` commands for configured workspaces.

Related file: [`const.py`](const.py).

### [tabulate.awk](tabulate.awk)

GNU awk program that formats a pipe- or colon-delimited text stream into a three-column table with word-wrapped cells. By default it treats input as `col1 | col2 | text`; with `-x`/`--comments` it parses `file:line: /* TODO: ... */` style records. Up to three trailing arguments override the column headers (defaults: `file`, `line`, `text`). Requires GNU awk for `BEGINFILE`, `match(..., arr)` and `xor()`.

Usage: `awk -f tabulate.awk [-x] [header1 header2 header3]`

### [todo](todo)

Very minimal action-items manager backed by a plain-text checkbox file. Interactive TUI supports adding, toggling, deleting, and navigating items (arrow keys, j/k, Ctrl-n/p, Space/Enter, A/N add, d delete, Esc/q exit); `--list`/`-l` prints only checkbox lines from the file.

Dependencies visible from the script: `bash`, `stty` (util-linux).

### [wallpaper.sh](wallpaper.sh)

Desktop wallpaper switcher that chooses a random JPG from `~/Pictures` and applies it through `feh` for i3 or `gsettings` for GNOME.

Dependencies visible from the script: `wmname`, `id`, `pgrep`, `grep`, `cut`, `tr`, `shuf`, `feh`, `gsettings`.

### [youtube-cli](youtube-cli)

Bash wrapper around `youtube-dl` and `mplayer`. It can bootstrap or update a local `youtube-dl` binary, persist its path into the script, list stream formats, and play a selected stream.

Dependencies visible from the script: `curl`, `gpg`, `mplayer`, `youtube-dl`.

### [yt-cli](yt-cli)

Bash wrapper around `yt-dlp` and `mplayer`. It can install or update a local `yt-dlp` binary with PGP signature verification, persist its path and version into the script, list available stream formats, and play a selected stream. Supports playlist files with shuffle, stores cookies in `cookies.txt`, and offers optional zenity GUI dialogs and an audio progress bar. Licensed Beer-ware.

Dependencies visible from the script: `curl`, `gpg`, `mplayer`, `yt-dlp`, `node`, `zenity` (optional GUI).
