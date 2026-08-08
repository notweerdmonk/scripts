# scripts

Personal utility scripts for shell workflows, debugging, reverse engineering, media handling, and small desktop tasks.

## File Index

- [README.md](README.md)
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- [DecompileVariables.py](DecompileVariables.py)
- [bgtimer](bgtimer)
- [bootstrap-chroot](bootstrap-chroot)
- [const.py](const.py)
- [cscope-setup](cscope-setup)
- [find_main.py](find_main.py)
- [newfile.sh](newfile.sh)
- [projects.sh](projects.sh)
- [rattles](rattles)
- [scrape-imgur-album](scrape-imgur-album)
- [slack-closet](slack-closet)
- [snakecase](snakecase)
- [syncp4repo](syncp4repo)
- [wallpaper.sh](wallpaper.sh)
- [youtube-cli](youtube-cli)

## Files

### [README.md](README.md)

Repository overview and file index for GitHub.

### [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)

Shared task plan and verification checklist used while preparing this README.

### [DecompileVariables.py](DecompileVariables.py)

Ghidra script that walks the program's `.data` segment, inspects typed data items, and writes C-style variable declarations to `data_variables.c`.

### [bootstrap-chroot](bootstrap-chroot)

Bash utility to bootstrap a chroot by copying selected binaries and their shared libraries, then mounting or unmounting required pseudo-filesystems. When sourced, it also registers shell completion.

Dependencies visible from the script: `bash`, `realpath`, `complete`, `which`, `ldd`, `findmnt`, `mount`, `umount`, `cp`, `mkdir`, `sed`.

### [bgtimer](bgtimer)

Background timer utility. When sourced in a shell, it registers a SIGUSR1 handler that executes a command on timeout. As an executable, it starts a background timer process that sends SIGUSR1 to a target shell after a specified time (RFC 2822 or ISO 8601 format).

The script determines its name dynamically and can be renamed; functionality remains intact.

Command to set timer: `source bgtimer <command>`
Command to modify timer command: `source bgtimer command <new_command>`
Command to cleanup: `source bgtimer cleanup`
Executable usage: `./bgtimer <pid> <time>`

### [const.py](const.py)

Tiny Python module that replaces itself with a write-once constant container object.

### [cscope-setup](cscope-setup)

Build helper for C/C++ trees. With `start`, it generates `cscope.files`, then creates a recursive `cscope` database if `cscope` is installed.

### [find_main.py](find_main.py)

Python script for use inside GDB. It automates locating a program entry point and `main`, and registers helper GDB commands for breakpoints, watchpoints, and stepping to relevant addresses.

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

Smol (303 lines, see [other](https://media1.tenor.com/m/CzbOTB8R8OYAAAAd/otters-otter.gif)), over-caffeinated key-value vault built on SQLite; it auto-routes keys into users, channels, messages, or message threads, validates the timestamp keys, uses `jq` to make sure message JASON isn’t lying, and lets you `put`, `get`, `get-all`, `list`, `search`, and `upsert` like a command-line librarian with trust issues. The WAL mode is there so the database can be a bit more concurrency-friendly, and the whole thing behaves like a structured spreadsheet that got a university degree in regex. Does or does not make you more productive, just does not try.


### [snakecase](snakecase)

AWK-driven refactoring helper that rewrites identifiers into `snake_case` inside one or more files. It supports optional backups and contains a release mode that strips debug blocks from the script itself.

Dependencies visible from the script: `awk`, `realpath`, `sed`, `cp`, `rm`.

### [syncp4repo](syncp4repo)

Python 3 utility for Perforce workflows. It reads command-line arguments or an XML task file, logs activity, and runs `p4 sync` or `p4 opened` commands for configured workspaces.

Related file: [`const.py`](const.py).

### [wallpaper.sh](wallpaper.sh)

Desktop wallpaper switcher that chooses a random JPG from `~/Pictures` and applies it through `feh` for i3 or `gsettings` for GNOME.

Dependencies visible from the script: `wmname`, `id`, `pgrep`, `grep`, `cut`, `tr`, `shuf`, `feh`, `gsettings`.

### [youtube-cli](youtube-cli)

Bash wrapper around `youtube-dl` and `mplayer`. It can bootstrap or update a local `youtube-dl` binary, persist its path into the script, list stream formats, and play a selected stream.

Dependencies visible from the script: `curl`, `gpg`, `mplayer`, `youtube-dl`.
