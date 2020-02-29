#
# system props for lge sm8150-common
#

# Audio
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    audio.deep_buffer.media=true \
    tunnel.audio.encode=true \
    audio.offload.buffer.size.kb=32 \
    audio.offload.gapless.enabled=true

# Bluetooth
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    vendor.bluetooth.soc=cherokee

# CNE
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.vendor.cne.feature=1

# CoreSight STM
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.debug.coresight.config=stm-events

# Graphics
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    debug.sf.enable_hwc_vds=1

# HWUI
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.hwui.texture_cache_size=72 \
    ro.hwui.layer_cache_size=48 \
    ro.hwui.r_buffer_cache_size=8 \
    ro.hwui.path_cache_size=32 \
    ro.hwui.gradient_cache_size=1 \
    ro.hwui.drop_shadow_cache_size=6 \
    ro.hwui.texture_cache_flushrate=0.4 \
    ro.hwui.text_small_cache_width=1024 \
    ro.hwui.text_small_cache_height=1024 \
    ro.hwui.text_large_cache_width=2048 \
    ro.hwui.text_large_cache_height=1024 \

# Media
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    av.offload.enable=true \
    media.settings.xml=/vendor/etc/media_profiles_vendor.xml

#Netflix custom property
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.netflix.bsp_rev=Q855-16947-1

# NFC
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.nfc.port=I2C

# Perf
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.vendor.qti.sys.fw.bg_apps_limit=64

# Priv-app permissions whitelist
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.control_privapp_permissions=enforce

# QC framework value-adds
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.vendor.qti.va_aosp.support=1

# Radio
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    DEVICE_PROVISIONED=1 \
    persist.vendor.data.mode=concurrent \
    ril.subscription.types=NV,RUIM \
    ro.telephony.default_network=22,22 \
    ro.vendor.use_data_netmgrd=true \
    telephony.lteOnCdmaDevice=1,1

# Sensors
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.vendor.sensors.enable.mag_filter=true

#Wifi
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    config.disable_rtt=true

# Wifi Display
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.debug.wfd.enable=1 \
    persist.sys.wfd.virtual=0

