#
# Automatically generated file. DO NOT MODIFY
#

TEE_DRIVER_PATH := vendor/samsung/a05m-tee

PRODUCT_SOONG_NAMESPACES += \
    $(TEE_DRIVER_PATH)

# Init
PRODUCT_COPY_FILES += \
    $(TEE_DRIVER_PATH)/prebuilts/tee_a05m.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/tee_a05m.rc

# Prebuilts
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(TEE_DRIVER_PATH)/prebuilts,$(TARGET_COPY_OUT_VENDOR)/tee)

