#!/bin/bash
# abort on error
set -e
# do not remove the next line. it is required
source build/envsetup.sh
# projects we can simply git pull
repos=(
	https://github.com/GlassROM/android_vendor_lineage
	https://github.com/GlassROM/android_frameworks_base
	https://github.com/GlassROM/android_packages_apps_LineageParts
	https://github.com/GlassROM/android_system_core
	https://github.com/GlassROM/android_packages_apps_Settings
	https://github.com/GlassROM/android_build_make
	https://github.com/GlassROM/android_packages_apps_Bluetooth
	https://github.com/GlassROM/android_system_bt
	https://github.com/GlassROM/android_bionic
	https://github.com/GlassROM/android_external_openssh
	https://github.com/GlassROM/android_system_sepolicy
	https://github.com/GlassROM/android_build_soong
	https://github.com/GlassROM/android_libcore
	https://github.com/GlassROM/android_system_extras
	https://github.com/GlassROM/android_external_conscrypt
	https://github.com/GlassROM/android_art
	https://github.com/GlassROM/android_packages_apps_Nfc
	https://github.com/GlassROM/android_bootable_recovery
	https://github.com/GlassROM/android_external_e2fsprogs
	https://github.com/GlassROM/android_system_bpf
	https://github.com/GlassROM/android_frameworks_native
)
for i in ${repos[@]}; do
	# for readability
	# first discard the first 36 bytes (upto .*android_)
	j=$(echo "$i" | dd bs=1 skip=36)
	# convert underscores to forward slashes
	j=$(echo "$j" | sed -e "s|_|/|g")
	# make sure we are in compile root/build top
	croot
	# enter the directory computed in j previously
	cd "$j"
	# pull the repo from the array (in i). Don't launch editor as this will open
	# too many confirmation windows
	git reset --hard
	git pull "$i" lineage-17.1 --no-edit
done

# clone
croot
# hardened malloc
cd external
[ -d "./hardened_malloc" ] || git clone https://github.com/GlassROM/hardened_malloc
cd hardened_malloc
git pull https://github.com/GrapheneOS/hardened_malloc --no-edit
croot

# trichrome
rm -rf vendor/chromium
cd vendor
git clone https://github.com/GlassROM/android_vendor_chromium chromium
cd chromium
git pull https://github.com/GrapheneOS/platform_external_vanadium --no-edit
cd ../lineage
git reset config/common.mk
git checkout config/common.mk
echo 'diff --git a/config/common.mk b/config/common.mk
index a5edad64..abd7c6ce 100644
--- a/config/common.mk
+++ b/config/common.mk
@@ -123,6 +123,10 @@ PRODUCT_PACKAGES += \
     Exchange2 \
     Terminal
 
+# Chromium packages
+PRODUCT_PACKAGES += \
+    TrichromeWebView
+
 # GlassROM packages
 PRODUCT_PACKAGES += \
     AuroraServices \
' | patch -p1
git add config/common.mk
git commit -m "add trichrome" --no-edit || true
croot

# remove packages we don't need
rm -rf packages/apps/AudioFX

# Bromite
cd external/chromium-webview/prebuilt
archs=(
	arm
	arm64
	x86
)
for i in ${archs[@]}; do
	cd "$i"
	curl -fsSL https://github.com/bromite/bromite/releases/download/81.0.4044.127/"$i"_SystemWebView.apk >webview.apk
	cd ..
done
git add .
git commit -m "add bromite" --no-edit || true
croot

#foss prebuilts
cd vendor
[ -d "./flossprebuilts" ] || git clone https://github.com/GlassROM/android_vendor_flossprebuilts flossprebuilts
cd flossprebuilts
git pull --rebase
croot

# ota hack - delete the rest of the script for a release build
cd packages/apps/Updater
echo 'diff --git a/AndroidManifest.xml b/AndroidManifest.xml
index d4d24c0..d662db2 100644
--- a/AndroidManifest.xml
+++ b/AndroidManifest.xml
@@ -18,8 +18,9 @@
         android:label="@string/app_name"
         android:requestLegacyExternalStorage="true"
         android:supportsRtl="true"
-        android:theme="@style/AppTheme"
-        android:usesCleartextTraffic="false">
+	android:networkSecurityConfig="@xml/network_security_config"
+	android:usesCleartextTraffic="true"
+        android:theme="@style/AppTheme">
 
         <activity
             android:name=".UpdatesActivity"
diff --git a/res/values/strings.xml b/res/values/strings.xml
index 34f2fd3..7abb8f5 100644
--- a/res/values/strings.xml
+++ b/res/values/strings.xml
@@ -32,7 +32,7 @@
           {type} - Build type
           {incr} - Incremental version
     -->
-    <string name="updater_server_url" translatable="false">https://download.lineageos.org/api/v1/{device}/{type}/{incr}</string>
+    <string name="updater_server_url" translatable="false">http://127.0.0.1:8001/updates.json</string>
 
     <string name="verification_failed_notification">Verification failed</string>
     <string name="verifying_download_notification">Verifying update</string>
diff --git a/res/xml/network_security_config.xml b/res/xml/network_security_config.xml
new file mode 100644
index 0000000..8ce94ff
--- /dev/null
+++ b/res/xml/network_security_config.xml
@@ -0,0 +1,5 @@
+<?xml version="1.0" encoding="utf-8"?>
+<network-security-config>
+    <base-config cleartextTrafficPermitted="true" >
+    </base-config>
+</network-security-config>
diff --git a/src/org/lineageos/updater/misc/Utils.java b/src/org/lineageos/updater/misc/Utils.java
index caf80c9..88e5672 100644
--- a/src/org/lineageos/updater/misc/Utils.java
+++ b/src/org/lineageos/updater/misc/Utils.java
@@ -140,7 +140,8 @@ public class Utils {
                 if (!compatibleOnly || isCompatible(update)) {
                     updates.add(update);
                 } else {
-                    Log.d(TAG, "Ignoring incompatible update " + update.getName());
+                    Log.d(TAG, "Incompatible update but adding anyway ( ͡° ͜ʖ ͡°) " + update.getName());
+		    updates.add(update);
                 }
             } catch (JSONException e) {
                 Log.e(TAG, "Could not parse update object, index=" + i, e);
@@ -161,9 +162,7 @@ public class Utils {
             serverUrl = context.getString(R.string.updater_server_url);
         }
 
-        return serverUrl.replace("{device}", device)
-                .replace("{type}", type)
-                .replace("{incr}", incrementalVersion);
+        return serverUrl;
     }
 
     public static String getUpgradeBlockedURL(Context context) {
' | patch -p1
git add .
git commit -m "adjust for debugging" --no-edit
