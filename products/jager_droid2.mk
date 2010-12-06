$(call inherit-product, vendor/jager/products/jager_common.mk)

# set up version info
include vendor/jager/products/jager_version.mk
build_name := JagerRom
build_version := $(build_version_major).$(build_version_minor).$(build_version_revision)

PRODUCT_NAME := jager_droid2
PRODUCT_BRAND := motorola
PRODUCT_DEVICE := droid2
PRODUCT_MODEL := DROID2
PRODUCT_MANUFACTURER := motorola

product_version := $(build_name)-$(build_version)-$(PRODUCT_MODEL)

# 2.2 build prop overrides
PRODUCT_BUILD_PROP_OVERRIDES := \
	BUILD_ID=VZW \
	BUILD_DISPLAY_ID=VZW \
	BUILD_NUMBER=2.2.19 \
	BUILD_DATE_UTC=1280959943 \
	TARGET_BUILD_TYPE=user \
	USER=dbretzm1 \
	BUILD_VERSION_TAGS=test-keys \
	PRODUCT_MODEL_INTERNAL=A955 \
	PRODUCT_BRAND=verizon \
	PRODUCT_NAME=droid2_vzw \
	TARGET_DEVICE=cdma_droid2 \
	BUILD_PRODUCT=droid2_vz2 \
	PRIVATE_BUILD_DESC="cdma_droid2-user 2.2 VZW 2.2.19 ota-rel-keys,release-keys" \
	BUILD_FINGERPRINT=verizon/droid2_vzw/cdma_droid2/droid2:2.2/VZW/22.19:user/ota-rel-keys,release-keys

# copy some prebuilts
PRODUCT_COPY_FILES +=  \
#	vendor/jager/prebuilt/motorola/droid2/system/media/bootanimation.zip:system/media/bootanimation.zip

# some standard overrides
PRODUCT_PROPERTY_OVERRIDES += \
	ro.modversion=$(product_version) \
	ro.rommanager.developerid=jager \
	ro.jager.build.name=$(build_name) \
	ro.jager.build.version=$(build_version) \
	
# include proprietaries for now
USE_PROPRIETARIES := \
	motorola

# include the device makefile
$(call inherit-product, device/motorola/droid2/device.mk)
