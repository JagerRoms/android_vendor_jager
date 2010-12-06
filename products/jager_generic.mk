# modified generic config

$(call inherit-product, vendor/jager/products/jager_core.mk)

PRODUCT_NAME := jager_generic
PRODUCT_BRAND := jager
PRODUCT_DEVICE :=

PRODUCT_PACKAGES += \
    AccountAndSyncSettings \
    CarHome \
    DeskClock \
    AlarmProvider \
    Bluetooth \
    Calculator \
    Calendar \
    Camera \
    CertInstaller \
    DrmProvider \
    Email \
    Gallery3D \
    LatinIME \
    Launcher2 \
    Mms \
    Music \
    Settings \
    Sync \
    Updater \
    CalendarProvider \
    SyncProvider
# The below were removed from the list above
# Protips \
# Provision \
# LatinIME \
# QuickSearchBox \

# end of modified generic config
