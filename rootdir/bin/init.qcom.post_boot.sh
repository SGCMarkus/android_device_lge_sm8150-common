#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2019, The Linux Foundation. All rights reserved.
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

target="$(getprop ro.board.platform)"

configure_zram_parameters()
{
    MemTotalStr="$(cat /proc/meminfo | grep MemTotal)"
    MemTotal=${MemTotalStr:16:8}

    # Zram disk - 75% for Go devices.
    # For 512MB Go device, size = 384MB, set same for Non-Go.
    # For 1GB Go device, size = 768MB, set same for Non-Go.
    # For >1GB and <=3GB Non-Go device, size = 1GB
    # For >3GB and <=4GB Non-Go device, size = 2GB
    # For >4GB Non-Go device, size = 4GB
    # And enable lz4 zram compression for Go targets.

    if [ -f /sys/block/zram0/disksize ]; then
        if [ -f /sys/block/zram0/use_dedup ]; then
            echo 1 > /sys/block/zram0/use_dedup
        fi

        echo 4294967296 > /sys/block/zram0/disksize

        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi
}

configure_read_ahead_kb_values()
{
    MemTotalStr="$(cat /proc/meminfo | grep MemTotal)"
    MemTotal=${MemTotalStr:16:8}

    echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb
    echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb
    echo 512 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
    echo 512 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
    echo 512 > /sys/block/dm-0/queue/read_ahead_kb
    echo 512 > /sys/block/dm-1/queue/read_ahead_kb
    echo 512 > /sys/block/dm-2/queue/read_ahead_kb
}

disable_core_ctl()
{
    if [ -f /sys/devices/system/cpu/cpu0/core_ctl/enable ]; then
        echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
    else
        echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/disable
    fi
}

function configure_memory_parameters() {
    # Set Memory parameters.
    #
    # Set per_process_reclaim tuning parameters
    # All targets will use vmpressure range 50-70,
    # All targets will use 512 pages swap size.
    #
    # Set Low memory killer minfree parameters
    # 32 bit Non-Go, all memory configurations will use 15K series
    # 32 bit Go, all memory configurations will use uLMK + Memcg
    # 64 bit will use Google default LMK series.
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # vmpressure_file_min threshold is always set slightly higher
    # than LMK minfree's last bin value for all targets. It is calculated as
    # vmpressure_file_min = (last bin - second last bin ) + last bin
    #
    # Set allocstall_threshold to 0 for all targets.
    #

ProductName="$(getprop ro.product.name)"
if [ "$ProductName" == "msmnile" ] || [ "$ProductName" == "kona" ] ; then
      # Enable ZRAM
      configure_zram_parameters
      configure_read_ahead_kb_values
      echo 0 > /proc/sys/vm/page-cluster
      echo 100 > /proc/sys/vm/swappiness
fi
}

start_hbtp()
{
        # Start the Host based Touch processing but not in the power off mode.
        bootmode="$(getprop ro.bootmode)"
        if [ "charger" != $bootmode ]; then
                start vendor.hbtp
        fi
}

case "$target" in
    "msmnile")
	# Core control parameters for gold
	echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
	echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
	echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
	echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
	echo 3 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

	# Core control parameters for gold+
	echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
	echo 60 > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
	echo 30 > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
	echo 100 > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
	echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/task_thres
	# Controls how many more tasks should be eligible to run on gold CPUs
	# w.r.t number of gold CPUs available to trigger assist (max number of
	# tasks eligible to run on previous cluster minus number of CPUs in
	# the previous cluster).
	#
	# Setting to 1 by default which means there should be at least
	# 4 tasks eligible to run on gold cluster (tasks running on gold cores
	# plus misfit tasks on silver cores) to trigger assitance from gold+.
	echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/nr_prev_assist_thresh

	# Disable Core control on silver
	echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

	# Setting b.L scheduler parameters
	echo 95 95 > /proc/sys/kernel/sched_upmigrate
	echo 85 85 > /proc/sys/kernel/sched_downmigrate
	echo 100 > /proc/sys/kernel/sched_group_upmigrate
	echo 10 > /proc/sys/kernel/sched_group_downmigrate
	echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

	# cpuset parameters
	echo 0-3 > /dev/cpuset/background/cpus
	echo 0-3 > /dev/cpuset/system-background/cpus
	echo 0-3 > /dev/cpuset/restricted/cpus
	echo 0-7 > /dev/cpuset/foreground/cpus

	# Turn off scheduler boost at the end
	echo 0 > /proc/sys/kernel/sched_boost

	# configure governor settings for silver cluster
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
        echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
	echo 1209600 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
	echo 576000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl

	# configure governor settings for gold cluster
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
	echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
        echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
	echo 1612800 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
	echo 1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl

	# configure governor settings for gold+ cluster
	echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
	echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
        echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
	echo 1612800 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
	echo 1 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

	# configure input boost settings
	echo "0:1785600 4:1056000 7:1056000" > /sys/module/cpu_boost/parameters/input_boost_freq
	echo "0:1785600 4:940800 7:940800" > /sys/module/cpu_boost/parameters/sub_boost_freq
	echo 80 > /sys/module/cpu_boost/parameters/input_boost_ms

	# Disable wsf, beacause we are using efk.
	# wsf Range : 1..1000 So set to bare minimum value 1.
        # LGE: set in init.lge.zramswap.sh
        # echo 1 > /proc/sys/vm/watermark_scale_factor

        echo 0-3 > /dev/cpuset/background/cpus
        echo 0-3 > /dev/cpuset/system-background/cpus

        # Enable oom_reaper
	if [ -f /sys/module/lowmemorykiller/parameters/oom_reaper ]; then
		echo 1 > /sys/module/lowmemorykiller/parameters/oom_reaper
	else
		echo 1 > /proc/sys/vm/reap_mem_on_sigkill
	fi

	# Enable bus-dcvs
	for device in /sys/devices/platform/soc
	do
	    for cpubw in $device/*cpu-cpu-llcc-bw/devfreq/*cpu-cpu-llcc-bw
	    do
		echo "bw_hwmon" > $cpubw/governor
		echo 40 > $cpubw/polling_interval
		echo "2288 4577 7110 9155 12298 14236 15258" > $cpubw/bw_hwmon/mbps_zones
		echo 4 > $cpubw/bw_hwmon/sample_ms
		echo 50 > $cpubw/bw_hwmon/io_percent
		echo 20 > $cpubw/bw_hwmon/hist_memory
		echo 10 > $cpubw/bw_hwmon/hyst_length
		echo 30 > $cpubw/bw_hwmon/down_thres
		echo 0 > $cpubw/bw_hwmon/guard_band_mbps
		echo 250 > $cpubw/bw_hwmon/up_scale
		echo 1600 > $cpubw/bw_hwmon/idle_mbps
		echo 14236 > $cpubw/max_freq
	    done

	    for llccbw in $device/*cpu-llcc-ddr-bw/devfreq/*cpu-llcc-ddr-bw
	    do
		echo "bw_hwmon" > $llccbw/governor
		echo 40 > $llccbw/polling_interval
		echo "1720 2929 3879 5931 6881 7980" > $llccbw/bw_hwmon/mbps_zones
		echo 4 > $llccbw/bw_hwmon/sample_ms
		echo 80 > $llccbw/bw_hwmon/io_percent
		echo 20 > $llccbw/bw_hwmon/hist_memory
		echo 10 > $llccbw/bw_hwmon/hyst_length
		echo 30 > $llccbw/bw_hwmon/down_thres
		echo 0 > $llccbw/bw_hwmon/guard_band_mbps
		echo 250 > $llccbw/bw_hwmon/up_scale
		echo 1600 > $llccbw/bw_hwmon/idle_mbps
		echo 6881 > $llccbw/max_freq
	    done

	    for npubw in $device/*npu-npu-ddr-bw/devfreq/*npu-npu-ddr-bw
	    do
		echo 1 > /sys/devices/virtual/npu/msm_npu/pwr
		echo "bw_hwmon" > $npubw/governor
		echo 40 > $npubw/polling_interval
		echo "1720 2929 3879 5931 6881 7980" > $npubw/bw_hwmon/mbps_zones
		echo 4 > $npubw/bw_hwmon/sample_ms
		echo 80 > $npubw/bw_hwmon/io_percent
		echo 20 > $npubw/bw_hwmon/hist_memory
		echo 6  > $npubw/bw_hwmon/hyst_length
		echo 30 > $npubw/bw_hwmon/down_thres
		echo 0 > $npubw/bw_hwmon/guard_band_mbps
		echo 250 > $npubw/bw_hwmon/up_scale
		echo 0 > $npubw/bw_hwmon/idle_mbps
		echo 0 > /sys/devices/virtual/npu/msm_npu/pwr
	    done

	    #Enable mem_latency governor for L3, LLCC, and DDR scaling
	    for memlat in $device/*cpu*-lat/devfreq/*cpu*-lat
	    do
		echo "mem_latency" > $memlat/governor
		echo 10 > $memlat/polling_interval
		echo 400 > $memlat/mem_latency/ratio_ceil
	    done

	    #Enable userspace governor for L3 cdsp nodes
	    for l3cdsp in $device/*cdsp-cdsp-l3-lat/devfreq/*cdsp-cdsp-l3-lat
	    do
		echo "cdspl3" > $l3cdsp/governor
	    done

	    #Enable compute governor for gold latfloor
	    for latfloor in $device/*cpu-ddr-latfloor*/devfreq/*cpu-ddr-latfloor*
	    do
		echo "compute" > $latfloor/governor
		echo 10 > $latfloor/polling_interval
	    done

	    #Gold L3 ratio ceil
	    for l3gold in $device/*cpu4-cpu-l3-lat/devfreq/*cpu4-cpu-l3-lat
	    do
		echo 4000 > $l3gold/mem_latency/ratio_ceil
	    done

	    #Prime L3 ratio ceil
	    for l3prime in $device/*cpu7-cpu-l3-lat/devfreq/*cpu7-cpu-l3-lat
	    do
		echo 20000 > $l3prime/mem_latency/ratio_ceil
	    done
	done

    if [ -f /sys/devices/soc0/hw_platform ]; then
        hw_platform="$(cat /sys/devices/soc0/hw_platform)"
    else
        hw_platform="$(cat /sys/devices/system/soc/soc0/hw_platform)"
    fi

    if [ -f /sys/devices/soc0/platform_subtype_id ]; then
        platform_subtype_id="$(cat /sys/devices/soc0/platform_subtype_id)"
    fi

    case "$hw_platform" in
        "MTP" | "Surf" | "RCM" )
            # Start Host based Touch processing
            case "$platform_subtype_id" in
                "0" | "1" | "2" | "4")
                    #start_hbtp
                    ;;
            esac
        ;;
        "HDK" )
            if [ -d /sys/kernel/hbtpsensor ] ; then
                start_hbtp
            fi
        ;;
    esac

    echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled
    configure_memory_parameters
    ;;
esac

product="$(getprop ro.build.product)"
case "$product" in
	"msmnile_au")
	#Setting the min and max supported frequencies
	reg_val="$(cat /sys/devices/platform/soc/780130.qfprom/qfprom0/nvmem | od -An -t d4)"
	feature_id=$(((reg_val >> 20) & 0xFF))

	if [ $feature_id == 0 ]; then
		echo "feature_id is 0 for SA8155"
		echo 1036800 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq
		echo 1171200 > /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
		echo 1785600 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
		echo 2131200 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
		echo 2131200 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_max_freq
		echo 2131200 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq
		echo 2419200 > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
                echo 4 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
                echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
	elif [ $feature_id == 1 ]; then
		echo "feature_id is 1 for SA8150"
		echo 1036800 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
		echo 1036800 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq
		echo 1056000 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq
		echo 1171200 > /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
		echo 1785600 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
		echo 1785600 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
		echo 1920000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
		echo 1920000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_max_freq
		echo 1920000 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq
		echo 2227200 > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
                echo 4 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
                echo 3 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
	else
		echo "unknown feature_id value" $feature_id
	fi
	;;
	*)
       ;;
esac

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+="$(getprop ro.build.id)"
    image_version+=":"
    image_version+="$(getprop ro.build.version.incremental)"
    image_variant="$(getprop ro.product.name)"
    image_variant+="-"
    image_variant+="$(getprop ro.build.type)"
    oem_version="$(getprop ro.build.version.codename)"
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config="$(getprop persist.console.silent.config)"
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
        ;;
    *)
        echo "Enable console config to $console_config"
        ;;
esac

# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path
