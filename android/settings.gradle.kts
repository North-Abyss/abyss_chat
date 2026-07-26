import java.io.File

// --- PATCH FOR CARGOKIT GRADLE 9.0 COMPATIBILITY ---
// The cargokit plugin uses Gradle exec APIs removed in Gradle 9.
// We rewrite plugin.gradle to use Java ProcessBuilder instead.
val pubCacheDir = File(System.getProperty("user.home"), ".pub-cache/hosted/pub.dev")
if (pubCacheDir.exists()) {
    pubCacheDir.walkTopDown().filter { it.name == "plugin.gradle" && it.absolutePath.contains("cargokit") }.forEach { file ->
        val content = file.readText()
        // Detect if this is a cargokit plugin file that needs patching
        if (content.contains("CargoKitBuildTask")) {
            // Generate the patched file by replacing the entire content
            val patched = """import java.nio.file.Paths
import org.apache.tools.ant.taskdefs.condition.Os

CargoKitPlugin.file = buildscript.sourceFile

apply plugin: CargoKitPlugin

class CargoKitExtension {
    String manifestDir;
    String libname;
}

abstract class CargoKitBuildTask extends DefaultTask {

    @Input
    String buildMode

    @Input
    String buildDir

    @Input
    String outputDir

    @Input
    String ndkVersion

    @Input
    String sdkDirectory

    @Input
    int compileSdkVersion;

    @Input
    int minSdkVersion;

    @Input
    String pluginFile

    @Input
    List<String> targetPlatforms

    @TaskAction
    def build() {
        if (project.cargokit.manifestDir == null) {
            throw new GradleException("Property 'manifestDir' must be set on cargokit extension");
        }

        if (project.cargokit.libname == null) {
            throw new GradleException("Property 'libname' must be set on cargokit extension");
        }

        def executableName = Os.isFamily(Os.FAMILY_WINDOWS) ? "run_build_tool.cmd" : "run_build_tool.sh"
        def path = Paths.get(new File(pluginFile).parent, "..", executableName);

        def manifestDir = Paths.get(project.buildscript.sourceFile.parent, project.cargokit.manifestDir)

        def rootProjectDir = project.rootProject.projectDir

        if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
            def chmodPb = new ProcessBuilder(['chmod', '+x', path.toString()])
            chmodPb.inheritIO()
            def chmodProc = chmodPb.start()
            if (chmodProc.waitFor() != 0) {
                throw new GradleException("chmod failed for " + path)
            }
        }

        def cmd = [path.toString(), 'build-gradle']
        def pb = new ProcessBuilder(cmd)
        pb.redirectErrorStream(true)
        def env = pb.environment()
        env.put("CARGOKIT_ROOT_PROJECT_DIR", rootProjectDir.toString())
        env.put("CARGOKIT_TOOL_TEMP_DIR", rootProjectDir.toString() + "/build/cargokit_tool_temp/" + project.name)
        env.put("CARGOKIT_MANIFEST_DIR", manifestDir.toString())
        env.put("CARGOKIT_CONFIGURATION", buildMode.toString())
        env.put("CARGOKIT_TARGET_TEMP_DIR", buildDir.toString())
        env.put("CARGOKIT_OUTPUT_DIR", outputDir.toString())
        env.put("CARGOKIT_NDK_VERSION", ndkVersion.toString())
        env.put("CARGOKIT_SDK_DIR", sdkDirectory.toString())
        env.put("CARGOKIT_COMPILE_SDK_VERSION", compileSdkVersion.toString())
        env.put("CARGOKIT_MIN_SDK_VERSION", minSdkVersion.toString())
        env.put("CARGOKIT_TARGET_PLATFORMS", targetPlatforms.join(","))
        env.put("CARGOKIT_JAVA_HOME", System.properties['java.home'].toString())
        def proc = pb.start()
        def reader = new java.io.BufferedReader(new java.io.InputStreamReader(proc.getInputStream()))
        def output = new StringBuilder()
        String line
        while ((line = reader.readLine()) != null) {
            println line
            output.append(line).append("\\n")
        }
        def exitCode = proc.waitFor()
        if (exitCode != 0) {
            throw new GradleException("CargoKit build failed with exit code " + exitCode + "\\n" + output.toString())
        }
    }
}
""" + content.substring(content.indexOf("class CargoKitPlugin"))
            file.writeText(patched)
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
