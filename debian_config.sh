#!/usr/bin/env bash
set -e -u
# Colored Environment Variables
if [ -e "$(command -v tput)" ]; then
	RED="$(tput setaf 1)$(tput bold)"
	GREEN="$(tput setaf 2)$(tput bold)"
	YELLOW="$(tput setaf 3)$(tput bold)"
	NOATTR="$(tput sgr0)"
else
	RED=""
	GREEN=""
	YELLOW=""
	NOATTR=""
fi

# Needed to Indicate if the configuration is still ongoing
touch /.setup_has_not_done

# Github repo page to fetch files
DEBDROID__URL_REPO="https://raw.githubusercontent.com/zavocc/debdroid/2.0"

# Suppress some Errors if trying to configure
rm -rf /etc/ld.so.preload
rm -rf /usr/local/lib/libdisableselinux.so

# Add 'contrib' component
[ -f /etc/apt/sources.list ] || sources_list="/etc/apt/sources.list.d/debian.sources"

if ! grep -q "main contrib" "${sources_list:-/etc/apt/sources.list}"; then
	sed -i "s/main/main contrib/g" "${sources_list:-/etc/apt/sources.list}"
fi

# Delete Docker Related files as if they're not essential and may cause problems
rm -rf /etc/apt/apt.conf.d/docker-*

# Fill the nameservers needed for networking
rm /etc/resolv.conf
cat > /etc/resolv.conf <<- EOM
nameserver 8.8.8.8
nameserver 8.8.4.4
EOM

# Perform Installation
echo "${GREEN}I: Updating packages if necessary, this may take several minutes, you also need to have a strong network connection and have a sufficient battery power to avoid interruption${NOATTR}"
apt update
apt upgrade -yy
echo "${GREEN}I: Installing some packages${NOATTR}"
apt install nano sudo tzdata procps curl dialog apt-utils command-not-found lsb-release locales -yy --no-install-recommends
echo "${GREEN}I: Perfoming necessary fixes${NOATTR}"
dpkg --configure -a ||:
apt install -f -y ||:
echo "${GREEN}I: Replacing system binaries with a stub${NOATTR}"
ln -fs /bin/true /usr/local/bin/udevadm
ln -fs /bin/true /usr/local/bin/dpkg-statoverride
echo "${GREEN}I: Trying to reconfigure it once again: fixes dpkg errors${NOATTR}"
dpkg --configure -a

# Update command-not-found database
echo "${GREEN}I: Populating ${YELLOW}command-not-found${GREEN} database${NOATTR}"
update-command-not-found
apt update

# Create 'addusers' script
cat > /usr/local/bin/addusers <<- EOM
#!/usr/bin/env bash
########################################################################
# This script allows to create one or more users easily
# And can be granted with sudo access automatically
#
# For Changing Users, user must value a username within echo from file:
# /.proot.debdroid/userinfo.rc
########################################################################
ARGUMENT="\$1"

if [ ! "\$(whoami)" == "root" ]; then
echo "${RED}Please run me as root to use this tool${NOATTR}"
exit 1
fi

# Check for zero argument
if [ -z "\$ARGUMENT" ]; then
echo "${RED}Please specify a user to add! this script only takes few arguments${NOATTR}"
exit 1
fi

# Add a user
echo "${GREEN}Adding a user \${ARGUMENT} and adding a sudoers file for a user to use administrative commands${NOATTR}"
if ! useradd -m "\${ARGUMENT}" -s /bin/bash; then
exit 1
fi
if ! passwd "\${ARGUMENT}"; then
exit 1
fi
echo "\${ARGUMENT}  ALL=(ALL:ALL)   NOPASSWD:ALL" > "/etc/sudoers.d/99-debdroid-user-\${ARGUMENT}"
echo "${GREEN}Successfully added a user \${ARGUMENT}${NOATTR}"
EOM

chmod 755 /usr/local/bin/addusers

# Download required files to launch debian
curl --insecure --fail --silent --output /.proot.debdroid/run_debian "${DEBDROID__URL_REPO}/run_debian.sh"
curl --insecure --fail --silent --output /.proot.debdroid/mountpoints.sh "${DEBDROID__URL_REPO}/mountpoints.sh"

# Preload libdisableselinux.so library to avoid messing up Debian from Android security features
case $(dpkg --print-architecture) in
	arm64|aarch64)
		curl --insecure --fail --silent --output /usr/local/lib/libdisableselinux.so "${DEBDROID__URL_REPO}/libs/arm64/libdisableselinux.so"
		;;
	armhf)
		curl --insecure --fail --silent --output /usr/local/lib/libdisableselinux.so "${DEBDROID__URL_REPO}/libs/armhf/libdisableselinux.so"
		;;
	i*86|x86)
		curl --insecure --fail --silent --output /usr/local/lib/libdisableselinux.so "${DEBDROID__URL_REPO}/libs/i386/libdisableselinux.so"
		;;
	amd64|x86_64)
		curl --insecure --fail --silent --output /usr/local/lib/libdisableselinux.so "${DEBDROID__URL_REPO}/libs/amd64/libdisableselinux.so"
		;;
esac

chmod 755 /usr/local/lib/libdisableselinux.so
echo /usr/local/lib/libdisableselinux.so >> /etc/ld.so.preload

# Enable interoperability if possible
if [ ! -e /.proot.debdroid/binfmt/corrosive-session ]; then
	mkdir /.proot.debdroid/binfmt -p
	echo 1 > /.proot.debdroid/binfmt/corrosive-session
fi

# Perform final configuration
echo "${GREEN}I: Performing Final Configuration${NOATTR}"
dpkg-reconfigure tzdata || :

# Multi-launguage environment
if ! dpkg-reconfigure locales; then
	echo "${GREEN}I: The language environment isn't configured: falling back to C.UTF-8${NOATTR}"
	echo "LANG=C.UTF-8" >> /etc/default/locale
	sleep 3
fi

# Implementation of hostname, this feature uniquely identifies your container, see https://github.com/termux/proot/issues/80 issue for more details
hostname_info=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --inputbox "Enter your hostname to uniquely identify your container, you may leave it blank for defaults, you may customize it again later by editing /etc/hostname" 12 40 \
			--output-fd 1
	)

if [ ! -z "${hostname_info}" ]; then
	echo "${hostname_info}" > /etc/hostname
else
	echo "${YELLOW}N: Falling Back to hostname: termux-debian${NOATTR}"
	echo "termux-debian" > /etc/hostname
fi

if [ ! -e /.proot.debdroid/userinfo.rc ]; then
	env_username=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --inputbox "Enter your desired username for your default user account" 9 40 \
			--output-fd 1
	)

	if [ ! -z "${env_username}" ]; then
		echo "${env_username}" > /.proot.debdroid/userinfo.rc
		useradd -s /bin/bash -m "${env_username}"
	else
		echo "${RED}N: No username is specified, falling back to defaults${NOATTR}"
		sleep 5
		echo "user" > /.proot.debdroid/userinfo.rc
		useradd -s /bin/bash -m "user"
	fi

	echo "$(cat /.proot.debdroid/userinfo.rc)   ALL=(ALL:ALL)   NOPASSWD:ALL" > /etc/sudoers.d/debdroid-user

	env_password=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --insecure --passwordbox "Enter your password for your default user account" 9 40 \
			--output-fd 1
	)

	if [ ! -z "${env_password}" ]; then
		echo "$(cat /.proot.debdroid/userinfo.rc)":"${env_password}" | chpasswd
	else
		echo "${RED}N: No password is specified, the default password is ${YELLOW}passw0rd${NOATTR}"
		sleep 5
		echo "$(cat /.proot.debdroid/userinfo.rc)":"passw0rd" | chpasswd
	fi
else
	echo "${YELLOW}I: The user account is already been set up... Skipping${NOATTR}"
fi

rm /.setup_has_not_done
