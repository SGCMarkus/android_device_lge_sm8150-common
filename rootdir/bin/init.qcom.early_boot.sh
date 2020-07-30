#! /vendor/bin/sh

# Copyright (c) 2012-2013,2016,2018,2019 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

export PATH=/vendor/bin

# Set platform variables
soc_hwplatform="$(cat /sys/devices/soc0/hw_platform)" 2> /dev/null
soc_hwid="$(cat /sys/devices/soc0/soc_id)" 2> /dev/null
soc_hwver="$(cat /sys/devices/soc0/platform_version)" 2> /dev/null


if [ -f /sys/class/drm/card0-DSI-1/modes ]; then
    echo "detect" > /sys/class/drm/card0-DSI-1/status
    mode_file=/sys/class/drm/card0-DSI-1/modes
    while read line; do
        fb_width=${line%%x*};
        break;
    done < $mode_file
fi

log -t BOOT -p i "MSM target '$1', SoC '$soc_hwplatform', HwID '$soc_hwid', SoC ver '$soc_hwver'"

if [ $fb_width -le 1600 ]; then
    setprop vendor.display.lcd_density 560
else
    setprop vendor.display.lcd_density 640
fi


# set Lilliput LCD density for ADP
product="$(getprop ro.build.product)"

case "$product" in
        "msmnile_au")
         setprop vendor.display.lcd_density 160
         echo 902400000 > /sys/class/devfreq/soc:qcom,cpu0-cpu-l3-lat/min_freq
         echo 1612800000 > /sys/class/devfreq/soc:qcom,cpu0-cpu-l3-lat/max_freq
         echo 902400000 > /sys/class/devfreq/soc:qcom,cpu4-cpu-l3-lat/min_freq
         echo 1612800000 > /sys/class/devfreq/soc:qcom,cpu4-cpu-l3-lat/max_freq
         ;;
        *)
        ;;
esac
case "$product" in
        "msmnile_gvmq")
         setprop vendor.display.lcd_density 160
         ;;
        *)
        ;;
esac
# Setup display nodes & permissions
# HDMI can be fb1 or fb2
# Loop through the sysfs nodes and determine
# the HDMI(dtv panel)

set_perms()
{
    #Usage set_perms <filename> <ownership> <permission>
    chown -h $2 $1
    chmod $3 $1
}

# check for the type of driver FB or DRM
if [ -e "/sys/class/graphics/fb0" ]; then
    # check for mdp caps
    file=/sys/class/graphics/fb0/mdp/caps
    if [ -f "$file" ]
    then
        setprop vendor.gralloc.disable_ubwc 1
        cat $file | while read line; do
          case "$line" in
                    *"ubwc"*)
                    setprop vendor.gralloc.enable_fb_ubwc 1
                    setprop vendor.gralloc.disable_ubwc 0
                esac
        done
    fi
else
    set_perms /sys/devices/virtual/hdcp/msm_hdcp/min_level_change system.graphics 0660
fi

# allow system_graphics group to access pmic secure_mode node
set_perms /sys/class/lcd_bias/secure_mode system.graphics 0660
set_perms /sys/class/leds/wled/secure_mode system.graphics 0660

boot_reason="$(cat /proc/sys/kernel/boot_reason)"
reboot_reason="$(getprop ro.boot.alarmboot)"
if [ "$boot_reason" = "3" ] || [ "$reboot_reason" = "true" ]; then
    setprop ro.vendor.alarm_boot true
else
    setprop ro.vendor.alarm_boot false
fi

# copy GPU frequencies to vendor property
if [ -f /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies ]; then
    gpu_freq="$(cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies)" 2> /dev/null
    setprop vendor.gpu.available_frequencies "$gpu_freq"
fi
