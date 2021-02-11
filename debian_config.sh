#!/bin/bash
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
URL_REPO="https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master"

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
apt install nano sudo tzdata procps curl dialog -yy --no-install-recommends
echo "${GREEN}I: Perfoming Necessary fixes${NOATTR}"
dpkg --configure -a ||:
apt install -f -y ||:
echo "${GREEN}I: Replacing System Binaries with a stub${NOATTR}"
install -m 755 /dev/null /usr/local/bin/udevadm
install -m 755 /dev/null /usr/local/bin/dpkg-statoverride
echo "${GREEN}I: Trying to reconfigure it once again: fixes dpkg errors${NOATTR}"
dpkg --configure -a

# Setup Environment Variables
echo "${GREEN}I: Setting up Environment Variables${NOATTR}"
cat > /etc/profile.d/50-debdroid-gros-integration.sh <<- EOM
#!/bin/bash

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
echo "All of your files are living outside the Termux's Prefix Directory, so a simple ${YELLOW}termux-reset${GREEN} command will not erase your debian container"
echo ""
echo "We hope you enjoy DebDroid, share your experience via Discord or make an issue report in"
echo "${YELLOW}https://github.com/WMCB-Tech/debdroid-ng/issues${NOATTR}"
touch /var/debdroid/.hushlogin

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/games:/usr/bin:/usr/sbin:/usr/games:/bin:/sbin"
export PULSE_SERVER="127.0.0.1"
export LANG="C.UTF-8"
export MOZ_FAKE_NO_SANDBOX="1"
export MOZ_DISABLE_GMP_SANDBOX="1"
export MOZ_DISABLE_CONTENT_SANDBOX="1"
EOM

curl --fail --silent --output /var/debdroid/libdebdroid.so "${URL_REPO}/run-debian.sh"

# Perform Final Configuration
echo "${GREEN}I: Performing Final Configuration${NOATTR}"
dpkg-reconfigure tzdata ||:

# Implementation of hostname, this feature uniquely identifies your container, see https://github.com/termux/proot/issues/80 issue for more details
hostname_info=$(
        dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
            --nocancel --inputbox "Enter your hostname to uniquely identify your container, you may leave it blank for defaults, you may customize it again later by editing /etc/hostname" 20 40 \
            3>&1 1>&2 2>&3 3>&- 
    )

if [ ! -z "${hostname_info}" ]; then
    echo "${hostname_info}" > /etc/hostname
else
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
        echo "user" > /var/debdroid/userinfo.rc
    fi
    echo "$(cat /var/debdroid/userinfo.rc)   ALL=(ALL:ALL)   NOPASSWD:ALL" > /etc/sudoers.d/99-debdroid-user
    env_password=$(
        dialog --title "Finish Debian Setup" --backtitle "DebDroid Configuration" \
            --nocancel --insecure --passwordbox "Enter your password for your default user account" 9 40 \
            3>&1 1>&2 2>&3 3>&-
    )
    if [ ! -z "${env_password}" ]; then
        echo "$(cat /var/debdroid/userinfo.rc)":"${env_password}" | chpasswd
    else
        echo "${RED}N: No password is specified, the default password is ${YELLOW}passw0rd${NOATTR}"
        sleep 3.1
        echo "$(cat /var/debdroid/userinfo.rc)":"passw0rd" | chpasswd
    fi
fi

rm /.setup_has_not_done