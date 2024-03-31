# FreeBSD Dektop with Xfce

This script installs a Xfce 4.18 desktop environment with Arc and Matcha Gtk themes on FreeBSD 14.x

Display drivers: Only the current nvidia FreeBSD (X64) and VMware display drivers are supported. When VMware is used, the screen size variable must be set to your needs.
Default: 2560x1440

Applications: Audacious, Catfish,  Chromium, doas, Glances, GNOME Archive manager, Firefox, Gimp, htop, KeePassXC, LibreOffice, lynis, mpv, neofetch, OctoPkg, Ristretto, rkhunter, Shotweel, sysinfo, Thunderbird, VIM, VLC.



## Getting Started

It is recommended that you start with a clean installation of FreeBSD 13.1 64-bit. If a user account already exists it should belong to the operator and wheel group so that administrative tasks can be performed. In addition a user account can be created during the installation of the FreeBSD Desktop environment.

### Prerequisites

- Installation of FreeBSD 14.0-RELEASE-amd64
- Display card: nvidea video card (550.xx series display driver) or installation on VMWare

### Installing

Log in as root or with your user account in a clean FreeBSD installation and download the install script from github. Then change the file permissions so that the installation script can be executed:

```
$ fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/install-xfce.sh
$ chmod u+x install-xfce.sh
```

The install script must be run as root, therefore switch to root ([su](https://www.freebsd.org/cgi/man.cgi?query=su&apropos=0&sektion=0&manpath=FreeBSD+13.0-current&arch=default&format=html)), if required before you run it:

```
# ./install-xfce.sh
```

Follow the instructions on screen. If you made a mistake answering the questions, press  ETC to abort the script. Afterwards run it again.



## Screenshots

<img src="./screenshots/bootscreen.png" width="600" height="300"/>

<img src="./screenshots/loginscreen.png" width="600" height="300"/>

<img src="./screenshots/desktop.png" width="600" height="300"/>

## Testing

The installation was only tested with the current nvidia drivers and under VMware on a desktop PC.

## License

This project is licensed under the BSD 3 License - See ``LICENSE`` for more information.

## Change notes

- 2022-07-23: New version of the freebsd- xfce-desktop install script using [dialog](https://www.freebsd.org/cgi/man.cgi?query=dialog&amp;sektion=1) (v2.0)
- 2021-09-21: Initial release of the freebsd-xfce-desktop install script (v1.0)

## Acknowledgments

[kamila.is](https://kamila.is/making/freebsd-wallpapers/) for the FreeBSD/Beastie wallpapers

Inspired by [broozar's](https://github.com/broozar/installDesktopFreeBSD)  desktop install script for FreeBSD
