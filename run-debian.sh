#!/data/data/com.termux/files/usr/bin/bash
# A Sourcefile to launch debian container within DebDroid
# This is not a launch command, this is required by the debdroid launch script
DEBIAN_FS="/data/data/com.termux/files/debian"
DEBIAN_HOSTNAME="/data/data/com.termux/files/debian/etc/hostname"
DEBIAN_USER_INFO="$(cat /data/data/com.termux/files/debian/var/debdroid/userinfo.rc)"
DEBIAN_MOUNTPOINTS_INFO="/data/data/com.termux/files/debian/var/debdroid/mountpoints.conf"

# Generate procfiles
gen_proc_files(){
# /proc/stat
cat > "${DEBIAN_FS}/var/debdroid/binds/fstat" <<- EOM
cpu  4058 0 3089 2779550 170 0 480 0 0 0
intr 283344 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 844257
btime 1613040871
processes 1002
procs_running 1
procs_blocked 0
softirq 405867 0 111579 0 72119 7205 0 14982 113430 0 86552
EOM
cat > "${DEBIAN_FS}/var/debdroid/binds/fversion" <<- EOM
Linux version 5.4.0-debdroid (termux@android) (gcc version 8.6.4 (GCC)) #1 SMP Tue Jun 23 12:58:10 UTC 2020
EOM
}