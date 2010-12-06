$(call inherit-product, vendor/jager/products/jager_common.mk)

# set up version info
include vendor/jager/products/jager_version.mk
build_name := JagerRom
build_version := $(build_version_major).$(build_version_minor).$(build_version_revision)

PRODUCT_NAME := jager_shadow
PRODUCT_BRAND := motorola
PRODUCT_DEVICE := shadow
PRODUCT_MODEL := DROIDX
PRODUCT_MANUFACTURER := motorola

product_version := $(build_name)-$(build_version)-$(PRODUCT_MODEL)

# 2.2 build prop overrides
PRODUCT_BUILD_PROP_OVERRIDES := \
	BUILD_ID=VZW \
	BUILD_DISPLAY_ID=VZW \
	BUILD_NUMBER=2.3.13 \
	BUILD_DATE_UTC=1282798200 \
	TARGET_BUILD_TYPE=user \
	USER=w30471 \
	BUILD_VERSION_TAGS=test-keys \
	PRODUCT_MODEL_INTERNAL=MB810 \
	PRODUCT_BRAND=verizon \
	PRODUCT_NAME=shadow_vzw \
	TARGET_DEVICE=cdma_shadow \
	BUILD_PRODUCT=shadow_vzw \
	PRIVATE_BUILD_DESC="cdma_shadow-user 2.2 VZW 2.3.13 ota-rel-keys,release-keys" \
	BUILD_FINGERPRINT=verizon/shadow_vzw/cdma_shadow/shadow:2.2/VZW/23.13:user/ota-rel-keys,release-keys

# copy some prebuilts
PRODUCT_COPY_FILES +=  \
#	vendor/jager/prebuilt/motorola/shadow/system/media/bootanimation.zip:system/media/bootanimation.zip

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
$(call inherit-product, device/motorola/shadow/device.mk)
