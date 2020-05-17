# -*-mic2-options-*- -A armv7l -f loop --pack-to=@NAME@.tar.gz -*-mic2-options-*-

# 
# Do not Edit! Generated by:
# kickstarter.py
# 

lang en_US.UTF-8
keyboard us
timezone --utc America/Los_Angeles
part / --fstype="ext4" --size=3500 --ondisk=mmcblk0 --label rootfs --fsoptions=defaults,noatime
part /opt --fstype="ext4" --size=512 --ondisk=mmcblk0 --label system-data --fsoptions=defaults,noatime
part /opt/usr --fstype="ext4" --size=3500 --ondisk=mmcblk0 --label user --fsoptions=defaults,noatime
part /mnt/initrd --size=7 --ondisk mmcblk0p --fstype=ext4 --label=ramdisk --extoptions="-b 1024"
part /mnt/initrd-recovery --size=12 --ondisk mmcblk0p --fstype=ext4 --label=ramdisk-recovery --extoptions="-b 1024 -O ^has_journal"


rootpw tizen 
xconfig --startxonboot
bootloader  --timeout=3  --append="rw vga=current splash rootwait rootfstype=ext4"   --ptable=gpt --menus="install:Wipe and Install:systemd.unit=system-installer.service:test"

desktop --autologinuser=guest  
user --name guest  --groups audio,video --password 'tizen'

repo --name=local --baseurl=file:///root/GBS-ANCHOR5-ROOT/tizen_anchor5/local/repos/tizen_anchor5/armv7l/ --priority=1

repo --name=unified-standard --baseurl=http://download.tizen.org/releases/milestone/tizen/unified/tizen-unified_20190523.1/repos/standard/packages/ --ssl_verify=no
repo --name=base-standard --baseurl=http://download.tizen.org/snapshots/tizen/base/tizen-base_20190503.1/repos/standard/packages/ --ssl_verify=no
#repo --name=unified-standard --baseurl=http://download.tizen.org/releases/milestone/tizen/unified/latest/repos/standard/packages/ --ssl_verify=no
#repo --name=base-standard --baseurl=http://download.tizen.org/snapshots/tizen/base/latest/repos/standard/packages/ --ssl_verify=no

%packages

# @ IoT Headless Base
building-blocks-root-Preset_iot_core
building-blocks-sub1-domain_Feature-Recovery
building-blocks-sub1-domain_Feature-Smartthings_App
dbus-tools
system-plugin-feature-namespace
system-plugin-feature-session-bind

# @ IoT Headed Base
building-blocks-root-Preset_iot_headed

# @ IoT Adaptation Artik530_710
alsa-utils
bluetooth-frwk-plugin-headed
building-blocks-sub1-Preset_boards-ARTIK530
building-blocks-sub1-Preset_partition-3parts_ramdisk
building-blocks-sub1-domain_Feature-BootAni
building-blocks-sub1-domain_Feature-DotNET
building-blocks-sub1-domain_Feature-Starter
building-blocks-sub1-domain_Feature-Upgrade
building-blocks-sub1-domain_Feature-WebAPI
building-blocks-sub2-Preset_boards-ARTIK530-Audio
building-blocks-sub2-Preset_boards-ARTIK530-Audio_Recording
building-blocks-sub2-Preset_boards-ARTIK530-BLE
building-blocks-sub2-Preset_boards-ARTIK530-Bluetooth
building-blocks-sub2-Preset_boards-ARTIK530-Bluetooth_CallAudio
building-blocks-sub2-Preset_boards-ARTIK530-Camera
building-blocks-sub2-Preset_boards-ARTIK530-Codec
building-blocks-sub2-Preset_boards-ARTIK530-DALi
building-blocks-sub2-Preset_boards-ARTIK530-Display
building-blocks-sub2-Preset_boards-ARTIK530-EFL
building-blocks-sub2-Preset_boards-ARTIK530-IM
building-blocks-sub2-Preset_boards-ARTIK530-Sensor
building-blocks-sub2-Preset_boards-ARTIK530-System
building-blocks-sub2-Preset_boards-ARTIK530-System_Device
building-blocks-sub2-Preset_boards-ARTIK530-WifiDirect
capi-media-player-display
capi-network-bluetooth-test
crash-worker
dali-csharp-binder
dali-csharp-binder-profile_common
download-fonts-service
dummyasm
elementary-tools
glibc-locale
gstreamer-utils
lbs-server-plugin-replay
libmm-display
memps
mtp-responder
org.tizen.bt-syspopup
org.tizen.bt-syspopup-profile_common
org.tizen.setting-profile_common
psmisc
pulseaudio-utils
sensord-profile_common
tizen-debug
tizen-locale
ug-bluetooth-efl
wifi-efl-ug
# Others




%end



%post
#!/bin/sh
echo "#################### generic-adaptation.post ####################"

# fix TIVI-2291
sed -ri "s/(^blacklist i8042.*$)/#fix from base-general.post \1/" /etc/modprobe.d/blacklist.conf


#!/bin/sh
echo "#################### generic-base.post ####################"

test ! -e /opt/var && mkdir -p /opt/var
test -d /var && cp -arf /var/* /opt/var/
rm -rf /var
ln -snf opt/var /var

test ! -e /opt/usr/home && mkdir -p /opt/usr/home
test -d /home && cp -arf /home/* /opt/usr/home/
rm -rf /home
ln -snf opt/usr/home /home

build_ts=$(date -u +%s)
build_date=$(date -u --date @$build_ts +%Y%m%d_%H%M%S)
build_time=$(date -u --date @$build_ts +%H:%M:%S)

sed -ri \
	-e 's|@BUILD_ID[@]|tizen-unified_20181024.1|g' \
	-e "s|@BUILD_DATE[@]|$build_date|g" \
	-e "s|@BUILD_TIME[@]|$build_time|g" \
	-e "s|@BUILD_TS[@]|$build_ts|g" \
	/etc/tizen-build.conf

# setup systemd default target for user session
cat <<'EOF' >>/usr/lib/systemd/user/default.target
[Unit]
Description=User session default target
EOF
mkdir -p /usr/lib/systemd/user/default.target.wants

# sdx: fix smack labels on /var/log
chsmack -a '*' /var/log

# create appfw dirs inside homes
function generic_base_user_exists() {
	user=$1
	getent passwd | grep -q ^${user}:
}

function generic_base_user_home() {
	user=$1
	getent passwd | grep ^${user}: | cut -f6 -d':'
}

function generic_base_fix_user_homedir() {
	user=$1
	generic_base_user_exists $user || return 1

	homedir=$(generic_base_user_home $user)
	mkdir -p $homedir/apps_rw
	for appdir in desktop manifest dbspace; do
		mkdir -p $homedir/.applications/$appdir
	done
	find $homedir -type d -exec chsmack -a User {} \;
	chown -R $user:users $homedir
	return 0
}

# fix TC-320 for SDK
. /etc/tizen-build.conf
[ "${TZ_BUILD_WITH_EMULATOR}" == "1" ] && generic_base_fix_user_homedir developer

# Add info.ini for system-info CAPI (TC-2047)
/etc/make_info_file.sh

#!/bin/sh
echo "#################### generic-users.post ####################"

if ! generic_base_user_exists owner; then
        # By default GUM will create users in /opt/etc/passwd, which is
        # additional users database suitable for end-user created accounts.
        # However, the 'owner' user is shipped by Tizen system itself and
        # it's its default user.  Consequently, it should always be available
        # and thus, it should be added to /etc/passwd.
        conf=/etc/gumd/gumd.conf
        origf=${conf}.orig
        mv -v $conf $origf
        sed -e 's,^\(PASSWD_FILE\).*,\1=/etc/passwd,' -e 's,^\(SHADOW_FILE\).*,\1=/etc/shadow,' <$origf >$conf
        gum-utils --offline --add-user --username=owner --usertype=admin --usecret=tizen
        mv -v $origf $conf
fi



#!/bin/sh

echo "############### iot-headless-base.post ################"

######### Execute pkg_initdb if there is no pkgmgr-tool pacakge
rpm -qa | grep pkgmgr-tool
if [ $? != 0 ]
then
pkg_initdb --ro
fi


#!/bin/sh
echo "#################### generic-wayland.post ####################"


#!/bin/sh
echo "#################### generic-middleware.post ####################"


#!/bin/sh
echo "#################### generic-applications.post ####################"


#!/bin/sh
echo "#################### generic-bluetooth.post ####################"


#!/bin/sh
echo "#################### generic-multimedia.post ####################"


#!/bin/sh
echo "#################### generic-desktop-applications.post ####################"

# depends on generic-base functions
function generic_desktop_applications_fix_userhome() {
	user=$1

	generic_base_user_exists $user || return 1
	homedir=$(generic_base_user_home $user)

	echo "Fix app_info.db of $user"
	chown -R $user:users $homedir/.applications/dbspace/
}

# fix TC-320 for SDK
. /etc/tizen-build.conf
# Disable to run below line because this results in always failure, so it can be regarded as useless.
#[ "${TZ_BUILD_WITH_EMULATOR}" == "1" ] && generic_desktop_applications_fix_userhome developer


#!/bin/sh
echo "#################### generic-crosswalk.post ####################"


#!/bin/sh
echo "############### common-crosswalk.post ################"

# start wrt widgets preinstall
rpm -qa | grep wrt-widget
if [ $? = 0 ]
then
prepare_widgets.sh
fi


#!/bin/sh
echo "############### common-license.post ################"

LICENSE_DIR=/usr/share/licenses
LICENSE_FILE=/usr/share/license.html
MD5_TEMP_FILE=/usr/share/temp_license_md5

if [[ -f $LICENSE_FILE ]]; then
	rm -f $LICENSE_FILE
fi

if [[ -f $MD5_TEMP_FILE ]]; then
	rm -f $MD5_TEMP_FILE
fi


cd $LICENSE_DIR
LICENSE_LIST=`ls */*`

for INPUT in $LICENSE_LIST; do
	if [[ -f $INPUT ]]; then
		PKG_NAME=`echo $INPUT|cut -d'/' -f1`
		echo `md5sum $INPUT` $PKG_NAME >> $MD5_TEMP_FILE
	fi
done

MD5_LIST=`cat $MD5_TEMP_FILE|awk '{print $1}'|sort -u`

echo "<html>" >> $LICENSE_FILE
echo "<head>" >> $LICENSE_FILE
echo "<meta name=\"viewport\" content=\"initial-scale=1.0\">" >> $LICENSE_FILE
echo "</head>" >> $LICENSE_FILE
echo "<body>" >> $LICENSE_FILE
echo "<xmp>" >> $LICENSE_FILE

for INPUT in $MD5_LIST; do
	PKG_LIST=`cat $MD5_TEMP_FILE|grep $INPUT|awk '{print $3}'`
	FILE_LIST=`cat $MD5_TEMP_FILE|grep $INPUT|awk '{print $2}'`
	PKG_FILE=`echo $FILE_LIST |awk '{print $1}'`

	echo "$PKG_LIST :" >> $LICENSE_FILE
	cat $PKG_FILE >> $LICENSE_FILE
	echo  >> $LICENSE_FILE
	echo  >> $LICENSE_FILE
	echo  >> $LICENSE_FILE
done

echo "</xmp>" >> $LICENSE_FILE
echo "</body>" >> $LICENSE_FILE
echo "</html>" >> $LICENSE_FILE

rm -rf $LICENSE_DIR/* $MD5_TEMP_FILE

#!/bin/sh
echo "#################### generic-dbus-policychecker.post ####################"
for f in /etc/dbus-1/system.d/*.conf; do
echo
echo "$0: Checking D-Bus policy file: $f"
dbus-policychecker "$f"
done

#!/bin/sh
echo "#################### generic-security.post ####################"

if [ -e /usr/share/security-config/set_capability ]; then
	echo 'Give capabilities to daemons via set_capability from security-config package'
	/usr/share/security-config/set_capability
fi
if [ -e /opt/share/security-config/test/image_test.sh ]; then
	echo 'Run security-test'
	/opt/share/security-config/test/image_test.sh
fi 

#!/bin/sh
echo "############### common-cleanup-directory.post ################"

# remove manuals, docs and headers
rm -rf /usr/include
rm -rf /usr/share/man
rm -rf /usr/share/doc


%end

%post --nochroot
####################### buildname.nochroot #######################
if [ -n "$IMG_NAME" ]; then
	echo "BUILD_ID=$IMG_NAME" >> $INSTALL_ROOT/etc/tizen-release
	echo "BUILD_ID=$IMG_NAME" >> $INSTALL_ROOT/etc/os-release
	echo "$IMG_NAME tizen-unified_20181024.1" >>$INSTALL_ROOT/etc/tizen-snapshot
fi

echo "############### backup-data.nochroot ################"

date +'[%m/%d %H:%M:%S %Z] backup-data.nochroot nochroot post script - start'

if [ -e $INSTALL_ROOT/usr/bin/build-backup-data.sh ]; then
    $INSTALL_ROOT/usr/bin/build-backup-data.sh
fi

date +'[%m/%d %H:%M:%S %Z] backup-data.nochroot nochroot post script - end'


%end

%runscript

%end

