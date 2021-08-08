#!/vendor/bin/sh

#
# Allow USB enumeration with default PID/VID
#
if [ -e /sys/class/android_usb/f_mass_storage/lun/nofua ];
then
    echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
fi
if [ -e /sys/class/android_usb/f_cdrom_storage/lun/nofua ];
then
    echo 1  > /sys/class/android_usb/f_cdrom_storage/lun/nofua
fi
if [ -e /sys/class/android_usb/f_mass_storage/rom/nofua ];
then
    echo 1  > /sys/class/android_usb/f_mass_storage/rom/nofua
fi

bootmode=`getprop ro.bootmode`
target_operator=`getprop ro.vendor.lge.build.target_operator`
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

    # boot overloading
    case "$target_operator" in
        "ATT" | "CRK")
            setprop vendor.lge.usb.boot.config.name mtp
            ;;
        *)
            setprop vendor.lge.usb.boot.config.name boot
            ;;
    esac
fi

if [ "$target_operator" == "VZW" ]; then
	devicename=`getprop ro.product.model`
	if [ -n "$devicename" ]; then
		echo "$devicename" > /sys/devices/platform/lge_android_usb/model_name
	fi
	swversion=`getprop ro.vendor.lge.swversion`
	if [ -n "$swversion" ]; then
		echo "$swversion" > /sys/devices/platform/lge_android_usb/sw_version
	fi
	subversion=`getprop ro.vendor.lge.swversion_rev`
	if [ -n "$subversion" ]; then
		echo "$subversion" > /sys/devices/platform/lge_android_usb/sub_version
	fi
fi

################################################################################
# QCOM
################################################################################

# Set the number of DIAG interfaces.
diag_count=`getprop ro.vendor.lge.usb.diag_count`
if [ "$diag_count" == "" ]; then
    setprop ro.vendor.lge.usb.diag_count 1
fi

# Set platform variables
soc_hwplatform=`cat /sys/devices/soc0/hw_platform 2> /dev/null`
soc_machine=`cat /sys/devices/soc0/machine 2> /dev/null`
soc_machine=${soc_machine:0:2}
soc_id=`cat /sys/devices/soc0/soc_id 2> /dev/null`

#
# Check ESOC for external modem
#
# Note: currently only a single MDM/SDX is supported
#
esoc_name=`cat /sys/bus/esoc/devices/esoc0/esoc_name 2> /dev/null`

if [ -d /sys/bus/esoc/devices ]; then
for f in /sys/bus/esoc/devices/*; do
    if [ -d $f ]; then
    if [ `grep -e "^MDM" -e "^SDX" $f/esoc_name` ]; then
            esoc_link=`cat $f/esoc_link`
            break
        fi
    fi
done
fi

target=`getprop ro.board.platform`

#
# Override USB default composition
# sm8250 : esoc_name [SDX55M] , ro.baseband [mdm] , target [kona]
# sm8350 : esoc_name [      ] , ro.baseband [msm] , target [lahaina]
# If USB persist config not set, set default configuration
#
#if [ "$(getprop persist.vendor.usb.config)" == "" -a \
#	"$(getprop init.svc.vendor.usb-gadget-hal-1-0)" != "running" ]; then
#    if [ "$esoc_name" == "" ]; then
#        case "$(getprop ro.baseband)" in
#            "msm")
#                case "$target" in
#                    "lahaina")
#                        if [ -d /config/usb_gadget/g1/functions/qdss.qdss ]; then
#                            setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,qdss,adb
#                        else
#                            setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,adb
#                        fi
#                        #setprop persist.vendor.usb.config diag,adb
#                    ;;
#                esac
#            ;;
#        esac
#    fi
#fi

# check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
	# Chip-serial is used for unique MSM identification in Product string
	msm_serial=`cat /sys/devices/soc0/serial_number`;
	msm_serial_hex=`printf %08X $msm_serial`
	machine_type=`cat /sys/devices/soc0/machine`
	setprop vendor.usb.product_string "$machine_type-$soc_hwplatform _SN:$msm_serial_hex"

	# ADB requires valid iSerialNumber; if ro.serialno is missing, use dummy
	serialnumber=`cat /config/usb_gadget/g1/strings/0x409/serialnumber 2> /dev/null`
	if [ "$serialnumber" == "" ]; then
		serialno=1234567
		echo $serialno > /config/usb_gadget/g1/strings/0x409/serialnumber
	fi
	setprop vendor.usb.configfs 1
else
        #
        # Do target specific things
        #
        case "$target" in
             "msm8996" | "msm8953")
                echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
                echo 131072 > /sys/module/g_android/parameters/mtp_tx_req_len
                echo 131072 > /sys/module/g_android/parameters/mtp_rx_req_len
             ;;
             "msm8937")
                case "$soc_id" in
                      "313" | "320")
                         echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
                      ;;
                esac
             ;;
        esac
fi

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.vendor.usb.config.extra`
if [ "$diag_extra" == "" ]; then
	setprop persist.vendor.usb.config.extra none
fi

# enable rps cpus on msm8937 target
setprop vendor.usb.rps_mask 0
case "$soc_id" in
	"294" | "295" | "353" | "354")
		setprop vendor.usb.rps_mask 40
	;;
esac

#
# apply to use qdss_diag in user mode
# SM6150(steppe) /SM6250 /SM6350(lagoon)
# SM7150 /SM7250(lito) /SM7350
# SM8150(msmnile) /SM8250(kona) /SM8350(lahaina)
#
case "$target" in
    "lahaina" | "kona" | "msmnile"  | "lito" | "steppe" | "steppe")
        chown -h root.oem_2902 /sys/devices/platform/soc/6048000.tmc/coresight-tmc-etr/block_size
        chmod 660 /sys/devices/platform/soc/6048000.tmc/coresight-tmc-etr/block_size
    ;;
esac

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

if [ -f "/vendor/bin/init.lge.usb.dev.sh" ]
then
    source /vendor/bin/init.lge.usb.dev.sh
fi
