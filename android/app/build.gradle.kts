plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
  id("org.jetbrains.kotlin.plugin.compose")
}

android {
  namespace = "mn.ekyc.example.liveness"
  compileSdk = 36

  defaultConfig {
    applicationId = "mn.ekyc.example.liveness"
    minSdk = 26 // the SDK's minimum
    targetSdk = 36
    versionCode = 1
    versionName = "1.0"
  }

  buildTypes {
    release {
      isMinifyEnabled = true // the SDK ships its own R8 rules
      proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
      signingConfig = signingConfigs.getByName("debug")
    }
  }
  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }
  buildFeatures { compose = true }
}

kotlin {
  compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}

dependencies {
  implementation("mn.ekyc:liveness-detector:5.0.0")

  implementation(platform("androidx.compose:compose-bom:2025.10.01"))
  implementation("androidx.compose.material3:material3")
  implementation("androidx.activity:activity-compose:1.11.0")
}
