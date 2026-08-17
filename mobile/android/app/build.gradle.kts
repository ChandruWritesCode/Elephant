plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // Restored because Flutter 3.13 still strictly requires it.
    id("org.jetbrains.kotlin.android") 
}

configurations.all {
    exclude(group = "com.google.android.play", module = "core")
    exclude(group = "com.google.android.play", module = "core-common")
    exclude(group = "com.google.android.play", module = "feature-delivery")
    exclude(group = "com.google.android.play", module = "app-update")
    exclude(group = "com.google.android.play", module = "tasks")
    exclude(group = "com.google.android.play", module = "split-install")
}

android {
    namespace = "in.commandlinecoding.elephant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "in.commandlinecoding.elephant"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Restored to support Flutter 3.13 Kotlin compilation
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)

androidComponents {
    onVariants { variant ->
        variant.outputs.forEach { output ->
            val abi = output.filters.find { 
                it.filterType == com.android.build.api.variant.FilterConfiguration.FilterType.ABI 
            }?.identifier
            
            val baseAbiCode = abiCodes[abi]
            if (baseAbiCode != null) {
                // FIXED: We read flutter.versionCode directly instead of mapping output.versionCode to itself.
                // This breaks the circular loop while still giving you the correct architecture suffix.
                val baseVersionCode = flutter.versionCode
                output.versionCode.set(baseVersionCode * 10 + baseAbiCode)
            }
        }
    }
}

project.afterEvaluate {
    tasks.configureEach {
        if (name.contains("minifyReleaseWithR8") || name.contains("minifyReleaseWithProguard") || name.contains("dexBuilderRelease")) {
            doFirst {
                logger.lifecycle("FOSS SANITIZER: Active. Sweeping intermediate files for non-free binaries...")
                
                val searchDirs = listOf(
                    File(project.layout.buildDirectory.asFile.get(), "intermediates/classes/release"),
                    File(project.layout.buildDirectory.asFile.get(), "intermediates/javac/release")
                )
                
                for (dir in searchDirs) {
                    if (dir.exists()) {
                        dir.walkBottomUp().forEach { file -> 
                            val normalizedPath = file.absolutePath.replace('\\', '/')
                            if (file.isDirectory && normalizedPath.endsWith("com/google/android/play/core")) {
                                file.deleteRecursively()
                                logger.lifecycle("Successfully removed vendor-shaded tracking package: $normalizedPath")
                            }
                        }
                    }
                }
            }
        }
    }
}

dependencies {}