#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

enabled_services=('choose-mirror.service' 'lightdm.service' 'NetworkManager')
systemctl enable ${enabled_services[@]}
systemctl set-default graphical.target

#Custom

#Fix perms
chmod 440 /etc/sudoers
#chown -R /etc/xdg root:root

#Disable annoying beeping
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# disable network stuff
rm /etc/udev/rules.d/81-dhcpcd.rules
systemctl disable dhcpcd sshd rpcbind.service

#Add files to skel
cp /usr/share/blackarch/config/bash/bashrc /etc/skel/.bashrc
sed -i 's/]#/]\\\\$/g' /etc/skel/.bashrc
cp /usr/share/blackarch/config/bash/bash_profile /etc/skel/.bash_profile

cp -r /usr/share/blackarch/config/vim/vim /etc/skel/.vim
cp /usr/share/blackarch/config/vim/vimrc /etc/skel/.vimrc

#cp /usr/share/blackarch/config/x11/xprofile /etc/skel/.xprofile
#cp /usr/share/blackarch/config/x11/Xresources /etc/skel/.Xresources
#cp /usr/share/blackarch/config/x11/Xdefaults /etc/skel/.Xresources

mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /etc/skel/.config/xfce4/panel
mkdir -p /etc/skel/.config/xfce4/terminal

cp /usr/share/blackarch/config/xfce/xfwm4.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
cp /usr/share/blackarch/config/xfce/xsettings.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cp /usr/share/blackarch/config/xfce/xfce4-desktop.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
cp /usr/share/blackarch/config/xfce/xfce4-panel.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
cp /usr/share/blackarch/config/xfce/whiskermenu-7.rc /etc/skel/.config/xfce4/panel/whiskermenu-7.rc
cp /usr/share/blackarch/config/xfce/terminalrc /etc/skel/.config/xfce4/terminal/terminalrc

#cp /etc/lightdm-blackarch/lightdm.conf /etc/lightdm/lightdm.conf #Post install
cp /etc/lightdm-blackarch/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf


#Create user
! getent group sudo && groupadd sudo
! getent group autologin && groupadd autologin
! id blackarch && useradd -m blackarch -G "sudo,autologin" #Should auto-copy files from skel
echo "blackarch:blackarch" | chpasswd
#Setup root
echo "root:blackarch" | chpasswd
chsh -s /bin/bash
cp /etc/skel/.bash* /root/
#Add installer to desktop
mkdir -p /home/blackarch/Desktop/
cp /usr/share/applications/calamares.desktop /home/blackarch/Desktop/calamares.desktop
chmod +x /home/blackarch/Desktop/calamares.desktop
chown blackarch:blackarch -R /home/blackarch/Desktop

###Remove once packages are in blackarch repo###
sed '$d' /etc/pacman.conf -i /etc/pacman.conf
sed '$d' /etc/pacman.conf -i /etc/pacman.conf
sed '$d' /etc/pacman.conf -i /etc/pacman.conf
sed '$d' /etc/pacman.conf -i /etc/pacman.conf

# remove special (not needed) files
rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
rm /root/{.automated_script.sh,.zlogin}

#Don't run blackmenu hook yet
#mv /etc/pacman.d/hooks/blackmenu.hook /etc/pacman.d/hooks/blackmenu.hook.bak
#setup repos and syncdb
curl -s https://blackarch.org/strap.sh | sh
pacman -Syy --noconfirm
pacman-key --init
pacman-key --populate blackarch archlinux
pkgfile -u
pacman -Fyy
pacman-db-upgrade
updatedb
sync

#Download optional files
mkdir -p /opt/installpkgs
pacman -Sw linux linux-headers linux-lts linux-lts-headers linux-hardened linux-hardened-headers networkmanager network-manager-applet libnm libmm-glib libndp libteam bluez-libs mobile-broadband-provider-info nm-connection-editor jansson zeromq libpgm libnma gcr libsodium iwd dhclient --cachedir /opt/installpkgs --noconfirm
#repo-add /opt/installpkgs/installpkgs.db.tar.gz /opt/installpkgs/*

#mv /etc/pacman.d/hooks/blackmenu.hook.bak /etc/pacman.d/hooks/blackmenu.hook
sed -i '36,41 s/^/#/' /usr/share/blackmenu/blackmenu.py
sed -i '42s/.*/thic="Papirus-Dark"/' /usr/share/blackmenu/blackmenu.py
blackmenu
sed -i '36,41 s/#//' /usr/share/blackmenu/blackmenu.py
sed -i '42s/.*//' /usr/share/blackmenu/blackmenu.py

mkdir -p /root/.config/xfce4/
echo "WebBrowser=midori" > /root/.config/xfce4/helpers.rc

#mv /etc/pacman.conf /etc/pacman.conf.bak
#cp /etc/pacman.d/installpkgs /etc/pacman.conf
repo-add /opt/installpkgs/installpkgs.db.tar.gz /opt/installpkgs/*
