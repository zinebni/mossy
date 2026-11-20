pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            if (localProperties.exists()) {
                localProperties.inputStream().use { properties.load(it) }
            }
            val rawPath =
                properties.getProperty("flutter.sdk")
                    ?: System.getenv("FLUTTER_ROOT")
                    ?: System.getenv("FLUTTER_HOME")
                    ?: error("flutter.sdk not set in local.properties and FLUTTER_ROOT env var not set")
            val cleanPath = rawPath.replace('\\', '/')
            if (properties.getProperty("flutter.sdk") == null) {
                localProperties.appendText("flutter.sdk=$cleanPath\n")
            }
            val androidHome = System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT")
            if (androidHome != null && properties.getProperty("sdk.dir") == null) {
                localProperties.appendText("sdk.dir=${androidHome.replace('\\', '/')}\n")
            }
            cleanPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
