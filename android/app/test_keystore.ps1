$storePass = $env:ANDROID_STORE_PASSWORD
keytool -list -v -keystore upload-keystore.jks -storepass $storePass