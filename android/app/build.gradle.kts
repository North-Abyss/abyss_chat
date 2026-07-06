plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.abyss.abyss_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.abyss.abyss_chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.withType<JavaCompile> {
    doFirst {
        val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (registrant.exists()) {
            var content = registrant.readText()
            if (content.contains("new com.mr.flutter.plugin.filepicker.FilePickerPlugin()")) {
                content = content.replace(
                    "flutterEngine.getPlugins().add(new com.mr.flutter.plugin.filepicker.FilePickerPlugin());",
                    "try { flutterEngine.getPlugins().add((io.flutter.embedding.engine.plugins.FlutterPlugin) Class.forName(\"com.mr.flutter.plugin.filepicker.FilePickerPlugin\").getDeclaredConstructor().newInstance()); } catch (Exception e) {}"
                )
                registrant.writeText(content)
                println("Patched GeneratedPluginRegistrant.java with reflection for file_picker to fix compile error!")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
