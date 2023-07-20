#!/usr/bin/env bash
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
DEBDROID__URL_REPO="https://raw.githubusercontent.com/zavocc/debdroid-ng/2.0"

# Suppress Some Errors if trying to configure
rm -rf /etc/ld.so.preload
rm -rf /usr/local/lib/libdisableselinux.so

# Add 'contrib non-free' componenets
sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list

# Delete Docker Related files as if they're not essential and may cause problems
rm -rf /etc/apt/apt.conf.d/docker-*

# Fill the nameservers needed for networking
rm /etc/resolv.conf
cat > /etc/resolv.conf <<- EOM
nameserver 8.8.8.8
nameserver 8.8.4.4
EOM

# Perform Installation
echo "${GREEN}I: Updating Packages if necessary, This may take several minutes, you also need to have a strong network connection and have a sufficient battery power to avoid interruption${NOATTR}"
apt update
apt upgrade -yy
echo "${GREEN}I: Installing some packages${NOATTR}"
apt install nano sudo tzdata procps curl dialog apt-utils command-not-found lsb-release locales -yy --no-install-recommends
echo "${GREEN}I: Perfoming Necessary fixes${NOATTR}"
dpkg --configure -a ||:
apt install -f -y ||:
echo "${GREEN}I: Replacing System Binaries with a stub${NOATTR}"
ln -fs /bin/true /usr/local/bin/udevadm
ln -fs /bin/true /usr/bin/dpkg-statoverride
echo "${GREEN}I: Trying to reconfigure it once again: fixes dpkg errors${NOATTR}"
dpkg --configure -a

# Update command-not-found database
echo "${GREEN}I: Populating ${YELLOW}command-not-found${GREEN} Database${NOATTR}"
update-command-not-found
apt update

# Setup Environment Variables
echo "${GREEN}I: Setting up Environment Variables${NOATTR}"
cat > /etc/profile.d/50-debdroid-gros-integration.sh <<- EOM
#!/usr/bin/env bash

if [ ! -e "/var/debdroid/.hushlogin" ]; then
echo "${GREEN} Welcome to Debian!"
echo ""
echo "To get started, grab apt-get and install your packages with ${YELLOW}apt install${GREEN} command"
echo ""
echo "You can add one or more users with the command ${YELLOW}addusers${GREEN} this command will setup not only the user account but also it sets up sudo access for second account"
echo "You can switch users by using ${YELLOW}su${GREEN} command"
echo ""
echo "To Update your debian system in just a tap, a simple ${YELLOW}debdroid reconfigure${GREEN} to ensure your container isn't outdated"
echo ""
echo "You can also setup your debian needs with the command ${YELLOW}debianize${GREEN}. this script will automate the entire process of installing your needs"
echo ""
echo "All of your files are living outside the Termux's Prefix Directory, so a simple ${YELLOW}termux-reset${GREEN} command will not erase your debian container"
touch /var/debdroid/.hushlogin
fi

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/games:/usr/bin:/usr/sbin:/usr/games:/bin:/sbin"
export PULSE_SERVER="127.0.0.1"
export MOZ_FAKE_NO_SANDBOX="1"
export MOZ_DISABLE_GMP_SANDBOX="1"
export MOZ_DISABLE_CONTENT_SANDBOX="1"
EOM

# Create 'addusers' script
cat > /usr/local/bin/addusers <<- EOM
#!/usr/bin/env bash
########################################################################
# This Script allows to create one or more users easily
# And can be granted with sudo access automatically
#
# For Changing Users, user must value a username within echo from file:
# /var/debdroid/userinfo.rc
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

curl --insecure --fail --silent --output /var/debdroid/run_debian "${DEBDROID__URL_REPO}/run_debian.sh"
curl --insecure --fail --silent --output /var/debdroid/mountpoints.conf "${DEBDROID__URL_REPO}/mountpoints.conf"
curl --insecure --fail --silent --output /usr/local/bin/debianize "${DEBDROID__URL_REPO}/debianize"
chmod 755 /usr/local/bin/debianize

# Preload libdisableselinux.so library to avoid messing up Debian from Android Security Features
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
echo "/usr/local/lib/libdisableselinux.so" > /etc/ld.so.preload

# Enable Interoperability if possible
if [ ! -e /var/debdroid/binfmt/corrosive-session ]; then
	mkdir /var/debdroid/binfmt -p
	echo 1 > /var/debdroid/binfmt/corrosive-session
fi

# Perform Final Configuration
echo "${GREEN}I: Performing Final Configuration${NOATTR}"
dpkg-reconfigure tzdata || :

# Multi-Launguage environment
if ! dpkg-reconfigure locales; then
	echo "${GREEN}I: The language environment isn't configured: falling back to C.UTF-8${NOATTR}"
	echo "export LANG=C.UTF-8" >> /etc/profile.d/50-debdroid-gros-integration.sh
fi

# Implementation of hostname, this feature uniquely identifies your container, see https://github.com/termux/proot/issues/80 issue for more details
hostname_info=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --inputbox "Enter your hostname to uniquely identify your container, you may leave it blank for defaults, you may customize it again later by editing /etc/hostname" 12 40 \
			3>&1 1>&2 2>&3 3>&-
	)

if [ ! -z "${hostname_info}" ]; then
	echo "${hostname_info}" > /etc/hostname
else
	echo "${YELLOW}N: Falling Back to hostname: termux-debian${NOATTR}"
	echo "termux-debian" > /etc/hostname
fi

if [ ! -e /var/debdroid/userinfo.rc ]; then
	env_username=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --inputbox "Enter your desired username for your default user account" 9 40 \
			3>&1 1>&2 2>&3 3>&-
	)

	if [ ! -z "${env_username}" ]; then
		echo "${env_username}" > /var/debdroid/userinfo.rc
		useradd -s /bin/bash -m "${env_username}"
	else
		echo "${RED}N: No username is specified, falling back to defaults${NOATTR}"
		sleep 5
		echo "user" > /var/debdroid/userinfo.rc
		useradd -s /bin/bash -m "user"
	fi

	echo "$(cat /var/debdroid/userinfo.rc)   ALL=(ALL:ALL)   NOPASSWD:ALL" > /etc/sudoers.d/debdroid-user

	env_password=$(
		dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
			--nocancel --insecure --passwordbox "Enter your password for your default user account" 9 40 \
			3>&1 1>&2 2>&3 3>&-
	)

	if [ ! -z "${env_password}" ]; then
		echo "$(cat /var/debdroid/userinfo.rc)":"${env_password}" | chpasswd
	else
		echo "${RED}N: No password is specified, the default password is ${YELLOW}passw0rd${NOATTR}"
		sleep 5
		echo "$(cat /var/debdroid/userinfo.rc)":"passw0rd" | chpasswd
	fi
else
	echo "${YELLOW}I: The User Account is already been set up... Skipping${NOATTR}"
fi

rm /.setup_has_not_done
