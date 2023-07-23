### Mountpoints for DebDroid
##########################################################
# To mount your custom mounts, the syntax should follows:
# mount+=("source:destination")
# or
# mount+=("source")
#
# Android partitions should not be disabled if interoperability is enabled
# You can disable it by typing
# echo 0 > /.proot.debdroid/binfmt/corrosive-session
##########################################################

##########################################################
# Core filesystem mountpoints
mount+=("/dev")
mount+=("/proc")
mount+=("/sys")
##########################################################

##########################################################
# Android mountpoints (Needed for executing host programs)
# Check each Android directories if present
for android_core_partitions in /apex /data /linkerconfig/ld.config.txt /odm /oem \
	/product /system /system_ext /vendor /property_contexts /plat_property_contexts /storage; do
		if [ -e "${android_core_partitions}" ]; then
			mount+=("${android_core_partitions}")
		fi
done

mount+=("/storage/emulated/0:/sdcard")
##########################################################

##########################################################
# Miscellanious mountpoints
mount+=("/dev/urandom:/dev/random")
mount+=("${PREFIX:-/data/data/com.termux/files/usr}/tmp:/tmp")
mount+=("${HOME:-/data/data/com.termux/files/home}:/home/termux_home")

# /dev/shm
mount+=("${DEBDROID__DEBIAN_FS}/run/shm:/dev/shm")
##########################################################

##########################################################
# Mountpoints for faking /proc entries (Comment it if you have permissive mode)
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fstat:/proc/stat")
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fversion:/proc/version")
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/floadavg:/proc/loadavg")
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fuptime:/proc/uptime")
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fvmstat:/proc/vmstat")
mount+=("${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fcap_last_cap:/proc/sys/kernel/cap_last_cap")
##########################################################

##########################################################
# Needed for some programs to utilize file descriptors (/dev/std*)
mount+=("/proc/self/fd/0:/dev/stdin")
mount+=("/proc/self/fd/1:/dev/stdout")
mount+=("/proc/self/fd/2:/dev/stderr")
##########################################################
