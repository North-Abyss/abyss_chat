import java.io.File

// --- PATcH FOR CARGOKIT GRADLE 9.0 COMPATIBILITY ---
val pubCacheDir = File(System.getProperty("user.home"), ".pub-cache/hosted/pub.dev")
if (pubCacheDir.exists()) {
    pubCacheDir.walkTopDown().filter { it.name == "plugin.gradle" && it.absolutePath.contains("cargokit") }.forEach { file ->
        val content = file.readText()
        val newContent = content.replace(Regex("((?:execOperations\\.)*(?:project\\.)*)?\\bexec\\s*\\{"), "this.getExecOperations().exec {")
        if (content != newContent) {
            file.writeText(newContent)
        }
    }
}
// ---------------------------------------------------

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
