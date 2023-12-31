# DebDroid
DebDroid - Debian for Android OS! \
[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/) [![made-for-VSCode](https://img.shields.io/badge/Made%20for-VSCode-1f425f.svg)](https://code.visualstudio.com/)

![debdroid](./images/neofetch.png)

# What is DebDroid?
DebDroid is an Debian Installer for the Android OS, this method of installing Debian on Android does not require root access and you can run your favorite Linux applications easily

> There's innovation in Linux. There are some really good technical features that I'm proud of. There are capabilities in Linux that aren't in other operating systems \
	-- Linus Torvalds

# About DebDroid
DebDroid will install Debian container within termux, creates a fresh Debian prefix for the location of the container, usually it will be placed in: \
`/data/data/com.termux/files/debian`

It lives outside the `$PREFIX` directory so if you decide to erase your broken `$PREFIX` directory, then your Debian container will remain intact.

This script also checks for updates so you can update it anytime by downloading it, this checks updates every time you open Debian container.

# Installation
You can install DebDroid by entering:
```
curl --location https://github.com/zavocc/debdroid/raw/master/debdroid.sh > debdroid
mv debdroid $PREFIX/bin
chmod +x $PREFIX/bin/debdroid
```

You can install Debian in just a few keystrokes by doing:
```
debdroid install
```
This will install Debian Buster. If you want to install other than Debian Buster, you can specify a suite by doing
```
debdroid install --suite sid
```
or
```
debdroid install --suite oldstable
```

If you have 64-bit processor, you can force install 32-bit version of Debian with `--32`
```
debdroid install --32 --suite sid
```

A list of supported releases can be listed by typing `debdroid install --list`

During Installation, it will update and upgrade the Debian system if necessary and installs required packages \
it will prompt you to enter your required information, this is necessary to capture user input, otherwise it will fallback to the following default credentials:
* User: `user`
* Password: `passw0rd`

![userinput](./images/userinput.png)

In case you interrupted your installation, you can do `debdroid.sh reconfigure` or `debdroid.sh configure` although this can be used to refresh Debian Container or to update it

# Starting Debian
You can start Debian by typing:
```
debdroid launch
```
Or to enter root shell:
```
debdroid launch --asroot
```

If you want to enter Debian other than shell, you can pass commands by doing:
```
debdroid launch -- [command]
```

## Setting up User Accounts
You can add users with the command `addusers` so you can create user account and add the user to sudoers access, syntax is:
```
sudo addusers <user>
```

You can set the default user account by echoing the value of your user
```
echo <username> > /.proot.debdroid/userinfo.rc
```
and restart to switch to new user account, although you may use `adduser` or `useradd` if you want

## Initializing Sounds
You can initialize sounds and transmit it via Termux's Pulseaudio, to enable sounds you may open xsdl app and keep it running, no need to configure `PULSE_SERVER` inside the guest

Although if you want to do it in Termux way, you need to enter this commands in termux
```
~ $ pulseaudio --start --exit-idle-time=-1
~ $ pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
```
If possible, you need to restart the container

## OpenGL acceleration
DebDroid will have `GALLIUM_DRIVER` environment variable synchronized from the host to use the same rendering mode in Debian. If the `GALLIUM_DRIVER` is not exported to Termux to specific value, it will use `llvmpipe` to it's default OpenGL rendering. Setting `export GALLIUM_DRIVER=virpipe` in Termux would automatically use that inside Debian guest.

## Running Termux Commands inside Debian
It's also possible to run host commands in the guest, and this can be used to run programs which are not available to the Debian repositories, this implementation is like from the feature of [WSL](https://docs.microsoft.com/en-us/windows/wsl/interop)

![interoperability](./images/termux-cmds-debian.png)

In some cases this may conflict with some dependencies or programs that is optimized for the usage with Termux and may cause some problems like compiling programs and having different libc linker, due to the way on [how they're set up between them](https://wiki.termux.com/wiki/Differences_from_Linux), or may impose security risks, if you don't want to happen, you can disable it by typing:
```
echo 0 > /.proot.debdroid/binfmt/corrosive-session
```
And restart your shell.

To Enable it back, type:
```
echo 1 > /.proot.debdroid/binfmt/corrosive-session
```

# Deleting Debian Container
If you don't want to use Debian anymore, you can do
```
debdroid purge
```

Keep in mind that if you do `termux-reset` then your Debian container will not be deleted.

# Updating Debian Containers
Sometimes, an update can be useful like newer bugfixes. To do that, a simple `debdroid reconfigure` will do the trick, but this also refreshes your Debian system

# Feature Requests and Bug Reports
You can bug reports by creating an [issue](https://github.com/WMCB-Tech/debdroid-ng/issues)

# Reference Links
* [PRoot](https://proot-me.github.io/)
* [Termux](https://termux.com)
* [Debian Wiki](https://wiki.Debian.org)
