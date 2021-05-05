# rsync-over-ssh-backup

Script to backup selected directories using rsync over ssh.

## Motivation

Unable (so far) to get `rsync` to ignore `.git` directories. This project created to document current process, record results and share with some helpful Reditors.

Usage: See instructions in `ssh_mirror.sh`. Ordinarily run from `cron`. Typical crontab entry:

```text
22 22 * * * /home/hbarta/bin/ssh_mirror.sh -h oak -r /srvpool/srv bin Documents Programming  >/tmp/srvpool-mirror.log 2>&1
```

Requirements

* passwordless login tto remote system
* helper script `prev_date.sh` in same directory as `ssh_mirror.sh`
* `rsync` (no longer a default install in recent Debian versions.)
