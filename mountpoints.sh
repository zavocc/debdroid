### Mountpoints for DebDroid
##########################################################
# To mount your custom mounts, the syntax should follows:
# prootargs+=" --bind=source:destination"
# or
# prootargs+=" --bind=source"
#
# Android partitions should not be disabled if interoperability is enabled
# You can disable it by typing
# echo 0 > /.proot.debdroid/binfmt/corrosive-session
##########################################################

##########################################################
# Core filesystem mountpoints
prootargs+=" --bind=/dev"
prootargs+=" --bind=/proc"
prootargs+=" --bind=/sys"
##########################################################

##########################################################
# Android mountpoints (Needed for executing host programs)
# Check each Android directories if present
for android_core_partitions in /apex /data /linkerconfig/ld.config.txt /odm /oem \
	/product /system /system_ext /vendor /property_contexts /plat_property_contexts /storage; do
		if [ -e "${android_core_partitions}" ]; then
			prootargs+=" --bind=${android_core_partitions}"
		fi
done

prootargs+=" --bind=/storage/emulated/0:/sdcard"
##########################################################

##########################################################
# Mountpoints for faking /proc entries (Comment it if you have permissive mode)
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fstat:/proc/stat"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fversion:/proc/version"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/floadavg:/proc/loadavg"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fuptime:/proc/uptime"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fvmstat:/proc/vmstat"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fcap_last_cap:/proc/sys/kernel/cap_last_cap"
##########################################################

##########################################################
# Needed for some programs to utilize file descriptors (/dev/std*)
prootargs+=" --bind=/proc/self/fd/0:/dev/stdin"
prootargs+=" --bind=/proc/self/fd/1:/dev/stdout"
prootargs+=" --bind=/proc/self/fd/2:/dev/stderr"
##########################################################

##########################################################
# Miscellanious mountpoints
prootargs+=" --bind=/dev/urandom:/dev/random"
prootargs+=" --bind=${PREFIX:-/data/data/com.termux/files/usr}/tmp:/tmp"
prootargs+=" --bind=${HOME:-/data/data/com.termux/files/home}:/home/termux_home"

# /dev/shm
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/run/shm:/dev/shm"
##########################################################
