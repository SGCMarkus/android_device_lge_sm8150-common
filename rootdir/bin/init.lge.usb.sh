#! /vendor/bin/sh

#
# Allow USB enumeration with default PID/VID
#
if [ -e /sys/class/android_usb/f_mass_storage/lun/nofua ]; then
    echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
fi
if [ -e /sys/class/android_usb/f_cdrom_storage/lun/nofua ]; then
    echo 1  > /sys/class/android_usb/f_cdrom_storage/lun/nofua
fi
if [ -e /sys/class/android_usb/f_mass_storage/rom/nofua ]; then
    echo 1  > /sys/class/android_usb/f_mass_storage/rom/nofua
fi

bootmode="$(getprop ro.bootmode)"
if [ "${bootmode:0:3}" != "qem" ] && [ "${bootmode:0:3}" != "pif" ]; then
    # correct the wrong usb property
    usb_config=$1
    case "$usb_config" in
        "" | "pc_suite" | "mtp_only" | "auto_conf")
            setprop vendor.lge.usb.persist.config mtp
            ;;
        "adb" | "pc_suite,adb" | "mtp_only,adb" | "auto_conf,adb")
            setprop vendor.lge.usb.persist.config mtp,adb
            ;;
        "ptp_only")
            setprop vendor.lge.usb.persist.config ptp
            ;;
        "ptp_only,adb")
            setprop vendor.lge.usb.persist.config ptp,adb
            ;;
        * ) ;; #USB persist config exists, do nothing
    esac
fi

################################################################################
# QCOM
################################################################################

# Set the number of DIAG interfaces.
diag_count="$(getprop ro.vendor.lge.usb.diag_count)"
if [ "$diag_count" == "" ]; then
    setprop ro.vendor.lge.usb.diag_count 1
fi

# Set platform variables
soc_hwplatform="$(cat /sys/devices/soc0/hw_platform)" 2> /dev/null

#
# Check ESOC for external modem
#
# Note: currently only a single MDM/SDX is supported
#
if [ -d /sys/bus/esoc/devices ]; then
for f in /sys/bus/esoc/devices/*; do
    if [ -d $f ]; then
    if [ `grep -e "^MDM" -e "^SDX" $f/esoc_name` ]; then
            esoc_link="$(cat $f/esoc_link)"
            break
        fi
    fi
done
fi

# check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
	# ADB requires valid iSerialNumber; if ro.serialno is missing, use dummy
	serialnumber="$(cat /config/usb_gadget/g1/strings/0x409/serialnumber 2> /dev/null)"
	if [ "$serialnumber" == "" ]; then
		serialno=1234567
		echo $serialno > /config/usb_gadget/g1/strings/0x409/serialnumber
	fi
	setprop vendor.usb.configfs 1
fi

#
# Initialize UVC conifguration.
#
if [ -d /config/usb_gadget/g1/functions/uvc.0 ]; then
	cd /config/usb_gadget/g1/functions/uvc.0

	echo 3072 > streaming_maxpacket
	echo 1 > streaming_maxburst
	mkdir control/header/h
	ln -s control/header/h control/class/fs/
	ln -s control/header/h control/class/ss

	mkdir -p streaming/uncompressed/u/360p
	echo "666666\n1000000\n5000000\n" > streaming/uncompressed/u/360p/dwFrameInterval

	mkdir -p streaming/uncompressed/u/720p
	echo 1280 > streaming/uncompressed/u/720p/wWidth
	echo 720 > streaming/uncompressed/u/720p/wWidth
	echo 29491200 > streaming/uncompressed/u/720p/dwMinBitRate
	echo 29491200 > streaming/uncompressed/u/720p/dwMaxBitRate
	echo 1843200 > streaming/uncompressed/u/720p/dwMaxVideoFrameBufferSize
	echo 5000000 > streaming/uncompressed/u/720p/dwDefaultFrameInterval
	echo "5000000\n" > streaming/uncompressed/u/720p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/360p
	echo "666666\n1000000\n5000000\n" > streaming/mjpeg/m/360p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/720p
	echo 1280 > streaming/mjpeg/m/720p/wWidth
	echo 720 > streaming/mjpeg/m/720p/wWidth
	echo 29491200 > streaming/mjpeg/m/720p/dwMinBitRate
	echo 29491200 > streaming/mjpeg/m/720p/dwMaxBitRate
	echo 1843200 > streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize
	echo 5000000 > streaming/mjpeg/m/720p/dwDefaultFrameInterval
	echo "5000000\n" > streaming/mjpeg/m/720p/dwFrameInterval

	echo 0x04 > /config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m/bmaControls

	mkdir -p streaming/h264/h/960p
	echo 1920 > streaming/h264/h/960p/wWidth
	echo 960 > streaming/h264/h/960p/wWidth
	echo 40 > streaming/h264/h/960p/bLevelIDC
	echo "333667\n" > streaming/h264/h/960p/dwFrameInterval

	mkdir -p streaming/h264/h/1920p
	echo "333667\n" > streaming/h264/h/1920p/dwFrameInterval

	mkdir streaming/header/h
	ln -s streaming/uncompressed/u streaming/header/h
	ln -s streaming/mjpeg/m streaming/header/h
	ln -s streaming/h264/h streaming/header/h
	ln -s streaming/header/h streaming/class/fs/
	ln -s streaming/header/h streaming/class/hs/
	ln -s streaming/header/h streaming/class/ss/
fi

################################################################################
# DEVICE
################################################################################

if [ -f "/vendor/bin/init.lge.usb.dev.sh" ]; then
    source /vendor/bin/init.lge.usb.dev.sh
fi
