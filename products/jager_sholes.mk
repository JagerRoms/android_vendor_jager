# Inherit some common jagermod stuff.
$(call inherit-product, vendor/jager/products/jager_common.mk)

# set up version info
# help from cvpcs 
include vendor/jager/products/jager_version.mk
build_name := jagerMod
build_version := $(build_version_major).$(build_version_minor).$(build_version_revision)


#
# Setup device specific product configuration.
#
PRODUCT_NAME := jager_sholes
PRODUCT_BRAND := motorola
PRODUCT_DEVICE := sholes
PRODUCT_MODEL := Droid
PRODUCT_MANUFACTURER := Motorola

ifdef JAGER_NIGHTLY 
    product_version := $(build_name)-$(shell date +%m%d%Y)-$(PRODUCT_MODEL)
else
    product_version := $(build_name)-$(build_version)-$(PRODUCT_MODEL)
endif

# 2.2 build prop overrides
PRODUCT_BUILD_PROP_OVERRIDES := \
	BUILD_DATE_UTC=1278317902 \
	BUILD_DISPLAY_ID=FRG22D \
	BUILD_FINGERPRINT=verizon/voles/sholes/sholes:2.2/FRG22D/50454:user/release-keys \
	BUILD_ID=FRG22D \
	BUILD_NUMBER=50454 \
	BUILD_VERSION_TAGS=release-keys \
	PRIVATE_BUILD_DESC="voles-user 2.2 FRG22D 50454 release-keys" \
	PRODUCT_NAME=voles \
	PRODUCT_BRAND=verizon \
	TARGET_DEVICE=sholes \
	TARGET_BUILD_TYPE=user \
	USER=android-build

# copy some prebuilts
PRODUCT_COPY_FILES +=  \
    vendor/jager/prebuilt/hdpi/media/bootanimation.zip:system/media/bootanimation.zip

# some standard overrides
PRODUCT_PROPERTY_OVERRIDES += \
	ro.modversion=$(product_version) \
	ro.rommanager.developerid=jager \
	ro.jager.build.name=$(build_name) \
	ro.jager.build.version=$(build_version)
#	ro.sf.lcd_density=192

# include proprietaries for now
USE_PROPRIETARIES := \
	motorola

# include the device makefile
$(call inherit-product, device/motorola/sholes/device.mk)
