$(call inherit-product, vendor/jager/products/jager_generic.mk)

# Generic PureMod product
PRODUCT_NAME := jager_common
PRODUCT_BRAND := jager
PRODUCT_DEVICE := 

# include hdpi packages
PRODUCT_PACKAGES += \
    ADWLauncher \
    FileManager \
    LiveWallpapers \
    LiveWallpapersPicker \
    SoundRecorder \
    Torch \
    VisualizationWallpapers \
    VoiceDialer \
    libRS \
    librs_jni
    # MagicSmokeWallpapers \

# Used by BusyBox
KERNEL_MODULES_DIR:=/system/lib/modules

# this is from CM system/core. it skips some symlinks if set. commenting out since we don't support it (yet)
# Tiny toolbox
#TINY_TOOLBOX:=true

# Enable Windows Media if supported by the board
WITH_WINDOWS_MEDIA:=true

# jagerMod specific product packages
PRODUCT_PACKAGES += \
    Superuser \
    SysInfo

# Copy over the changelog to the device
#PRODUCT_COPY_FILES += \
#    vendor/jager/CHANGELOG.mkdn:system/etc/CHANGELOG-CM.txt

# Common jager overlay
PRODUCT_PACKAGE_OVERLAYS += vendor/jager/overlay/common

# Bring in some audio files
include frameworks/base/data/sounds/AudioPackage4.mk

PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.notification_sound=Droid.ogg \
    ro.telephony.call_ring.delay=1000

PRODUCT_COPY_FILES += \
     vendor/jager/prebuilt/common/bin/sysinit.jager:system/bin/sysinit.jager \
     vendor/jager/prebuilt/common/xbin/htop:system/xbin/htop \
     vendor/jager/prebuilt/common/xbin/irssi:system/xbin/irssi \
     vendor/jager/prebuilt/common/xbin/lsof:system/xbin/lsof \
     vendor/jager/prebuilt/common/bin/backuptool.sh:system/bin/backuptool.sh \
     vendor/jager/prebuilt/common/etc/terminfo/l/linux:system/etc/terminfo/l/linux \
     vendor/jager/prebuilt/common/etc/terminfo/u/unknown:system/etc/terminfo/u/unknown \
     vendor/jager/prebuilt/common/etc/profile:system/etc/profile \
     vendor/jager/prebuilt/common/etc/init.d/00_banner:system/etc/init.d/00_banner \
     vendor/jager/prebuilt/common/xbin/openvpn-up.sh:system/xbin/openvpn-up.sh \
     vendor/jager/prebuilt/common/etc/init.jager.rc:system/etc/init.jager.rc \
     vendor/jager/prebuilt/common/etc/resolv.conf:system/etc/resolv.conf

#    vendor/jager/prebuilt/common/etc/apns-conf.xml:system/etc/apns-conf.xml \
#    vendor/jager/prebuilt/common/etc/sysctl.conf:system/etc/sysctl.conf \
#    vendor/jager/prebuilt/common/etc/init.d/01sysctl:system/etc/init.d/01sysctl \
#    vendor/jager/prebuilt/common/etc/init.d/03firstboot:system/etc/init.d/03firstboot \
#    vendor/jager/prebuilt/common/etc/init.d/04modules:system/etc/init.d/04modules \
#    vendor/jager/prebuilt/common/etc/init.d/20userinit:system/etc/init.d/20userinit \
#    vendor/jager/prebuilt/common/xbin/powertop:system/xbin/powertop \

#PRODUCT_COPY_FILES += \
#    vendor/jager/prebuilt/common/etc/init.d/05mountsd:system/etc/init.d/05mountsd \
#    vendor/jager/prebuilt/common/etc/init.d/10apps2sd:system/etc/init.d/10apps2sd

# Always run in insecure mode, enables root on user build variants
ADDITIONAL_DEFAULT_PROPERTIES += ro.secure=0

ifdef JAGER_WITH_GOOGLE
    PRODUCT_COPY_FILES += \
        vendor/jager/proprietary/CarHomeGoogle.apk:./system/app/CarHomeGoogle.apk \
        vendor/jager/proprietary/CarHomeLauncher.apk:./system/app/CarHomeLauncher.apk \
        vendor/jager/proprietary/Facebook.apk:./system/app/Facebook.apk \
        vendor/jager/proprietary/GenieWidget.apk:./system/app/GenieWidget.apk \
        vendor/jager/proprietary/Gmail.apk:./system/app/Gmail.apk \
        vendor/jager/proprietary/GoogleBackupTransport.apk:./system/app/GoogleBackupTransport.apk \
        vendor/jager/proprietary/GoogleCalendarSyncAdapter.apk:./system/app/GoogleCalendarSyncAdapter.apk \
        vendor/jager/proprietary/GoogleContactsSyncAdapter.apk:./system/app/GoogleContactsSyncAdapter.apk \
        vendor/jager/proprietary/GoogleFeedback.apk:./system/app/GoogleFeedback.apk \
        vendor/jager/proprietary/GooglePartnerSetup.apk:./system/app/GooglePartnerSetup.apk \
        vendor/jager/proprietary/GoogleQuickSearchBox.apk:./system/app/GoogleQuickSearchBox.apk \
        vendor/jager/proprietary/GoogleServicesFramework.apk:./system/app/GoogleServicesFramework.apk \
        vendor/jager/proprietary/HtcCopyright.apk:./system/app/HtcCopyright.apk \
        vendor/jager/proprietary/HtcEmailPolicy.apk:./system/app/HtcEmailPolicy.apk \
        vendor/jager/proprietary/HtcSettings.apk:./system/app/HtcSettings.apk \
        vendor/jager/proprietary/LatinImeTutorial.apk:./system/app/LatinImeTutorial.apk \
        vendor/jager/proprietary/Maps.apk:./system/app/Maps.apk \
        vendor/jager/proprietary/MarketUpdater.apk:./system/app/MarketUpdater.apk \
        vendor/jager/proprietary/MediaUploader.apk:./system/app/MediaUploader.apk \
        vendor/jager/proprietary/NetworkLocation.apk:./system/app/NetworkLocation.apk \
        vendor/jager/proprietary/OneTimeInitializer.apk:./system/app/OneTimeInitializer.apk \
        vendor/jager/proprietary/PassionQuickOffice.apk:./system/app/PassionQuickOffice.apk \
        vendor/jager/proprietary/SetupWizard.apk:./system/app/SetupWizard.apk \
        vendor/jager/proprietary/Street.apk:./system/app/Street.apk \
        vendor/jager/proprietary/Talk.apk:./system/app/Talk.apk \
        vendor/jager/proprietary/Twitter.apk:./system/app/Twitter.apk \
        vendor/jager/proprietary/Vending.apk:./system/app/Vending.apk \
        vendor/jager/proprietary/VoiceSearch.apk:./system/app/VoiceSearch.apk \
        vendor/jager/proprietary/YouTube.apk:./system/app/YouTube.apk \
        vendor/jager/proprietary/googlevoice.apk:./system/app/googlevoice.apk \
        vendor/jager/proprietary/com.google.android.maps.xml:./system/etc/permissions/com.google.android.maps.xml \
        vendor/jager/proprietary/features.xml:./system/etc/permissions/features.xml \
        vendor/jager/proprietary/com.google.android.maps.jar:./system/framework/com.google.android.maps.jar \
        vendor/jager/proprietary/libspeech.so:./system/lib/libspeech.so \
        vendor/jager/proprietary/libvoicesearch.so:./system/lib/libvoicesearch.so
else
    PRODUCT_PACKAGES += \
        Provision \
        QuickSearchBox
endif

PRODUCT_LOCALES := en_US en_GB fr_FR it_IT de_DE es_ES
