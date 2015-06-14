Simple shell script to run backups using rsync. See
[Time Machine for every Unix out there](https://blog.interlinked.org/tutorials/rsync_time_machine.html)
for more info.

All you need is to run ./backup-mj41cz.sh and follow instructions.

Features:
* use rsync to backup
 * --exclude-from - to allow define exlude list
 * --link-dest - to save space using hard links
* easy way to continue failed (or aborted/Ctrl+C) backup
* 'init' option to setup config directory with example configuration
