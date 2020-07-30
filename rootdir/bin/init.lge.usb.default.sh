#! /vendor/bin/sh

waitForState()
{
    local i
    local state=$1
    local value
    for i in {1..20}; do
        value=`getprop vendor.lge.usb.state`
        if [ "x${state}" = "x${value}" ]; then
            echo 0
            return
        fi
        sleep 0.050
    done

    echo 1
    return
}

setUsbConfig()
{
    setprop vendor.lge.usb.config $1
    waitForState $1
}

updateDefaultFunction()
{
    setprop vendor.lge.usb.persist.config $1
    setprop vendor.lge.usb.config $1
}

usb_config=$1
case "$usb_config" in
    "boot") #factory status, select default
        setUsbConfig none
        updateDefaultFunction $default
    ;;
    "boot,adb") #factory status, select default
        setUsbConfig none
        updateDefaultFunction ${default},adb
    ;;
    *) ;; #USB persist config exists, do nothing
esac
