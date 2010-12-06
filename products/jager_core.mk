# modified core config

PRODUCT_NAME := jager_core
PRODUCT_BRAND := jager
PRODUCT_DEVICE :=

PRODUCT_POLICY := android.policy_phone

# The below were removed from the list above
#
#PRODUCT_PROPERTY_OVERRIDES := \
# ro.config.notification_sound=OnTheHunt.ogg \
# ro.config.alarm_alert=Alarm_Classic.ogg

PRODUCT_PACKAGES := \
    framework-res \
    Browser \
    Contacts \
    Home \
    HTMLViewer \
    Phone \
    ContactsProvider \
    DownloadProvider \
    MediaProvider \
    PicoTts \
    SettingsProvider \
    TelephonyProvider \
    TtsService \
    VpnServices \
    UserDictionaryProvider \
    PackageInstaller \
    DefaultContainerService \
    ApplicationsProvider
    
	#Bugreport

PRODUCT_PROPERTY_OVERRIDES += \
    media.stagefright.enable-player=true \
    media.stagefright.enable-meta=true \
    media.stagefright.enable-scan=true \
    media.stagefright.enable-http=true
# end modified core config
