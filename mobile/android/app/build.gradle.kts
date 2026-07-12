plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
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

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
                        dir.walkTopDown().forEach { file ->
                            if (file.isDirectory && file.absolutePath.endsWith("com/google/android/play/core")) {
                                file.deleteRecursively()
                                logger.lifecycle("Successfully deleted shaded directory: ${file.absolutePath}")
                            }
                        }
                    }
                }
            }
        }
    }
}

dependencies {}
