# Inherit some common stuff.
$(call inherit-product, vendor/jager/products/jager_common.mk)

# set up version info
# help from cvpcs 
include vendor/jager/products/jager_version.mk
build_name := JagerRom
build_version := $(build_version_major).$(build_version_minor).$(build_version_revision)

#
# Setup device specific product configuration.
#
PRODUCT_NAME := jager_inc
PRODUCT_BRAND := htc
#PRODUCT_BRAND := verizon_wwe
PRODUCT_DEVICE := inc
PRODUCT_MODEL := ADR6300
PRODUCT_MANUFACTURER := HTC

ifdef JAGER_NIGHTLY
    product_version := $(build_name)-$(shell date +%m_%d_%Y_%H:%M:%S)-$(PRODUCT_MODEL)
else
    product_version := $(build_name)-$(shell date +%m_%d_%Y_%H:%M:%S)-$(PRODUCT_MODEL)
#    product_version := $(build_name)-$(build_version)-$(PRODUCT_MODEL)
endif

PRODUCT_BUILD_PROP_OVERRIDES += \
	BUILD_ID=FRF91 \
        BUILD_DISPLAY_ID=FRG83 \
	PRODUCT_NAME=inc \
	BUILD_FINGERPRINT=verizon_wwe/inc/inc/inc:2.2/FRF91/231334:user/release-keys \
	PRODUCT_BRAND=verizon_wwe \
	TARGET_BUILD_TYPE=user \
	USER=android-build \
	BUILD_VERSION_TAGS=release-keys \
	PRIVATE_BUILD_DESC="3.21.605.1 CL231334 release-keys" \
	PRODUCT_MANUFACTURER=HTC

# already set in device.mk
#PRODUCT_PROPERTY_OVERRIDES += \
#	ro.product.version=3.21.605.1

# Extra Passion overlay
#PRODUCT_PACKAGE_OVERLAYS += vendor/jager/overlay/inc


# copy some prebuilts
#PRODUCT_COPY_FILES +=  \
#    vendor/jager/prebuilt/hdpi/media/bootanimation.zip:system/media/bootanimation.zip

# some standard overrides
PRODUCT_PROPERTY_OVERRIDES += \
	ro.modversion=$(product_version) \
	ro.rommanager.developerid=jager \
	ro.jager.build.name=$(build_name) \
	ro.jager.build.version=$(build_version) \

# include proprietaries for now
USE_PROPRIETARIES := \
	htc

$(call inherit-product, device/htc/inc/device.mk)
