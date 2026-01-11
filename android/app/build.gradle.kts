import java.util.Properties
import java.io.FileInputStream

// 1. Đọc file key.properties bằng Java Properties (Chuẩn và an toàn nhất)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sosbattery.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // 2. Cấu hình signingConfigs PHẢI nằm trước buildTypes
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sosbattery.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 3
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // 3. Sử dụng cấu hình release đã tạo ở trên
            signingConfig = signingConfigs.getByName("release")
            
            // Nếu muốn tối ưu code (giảm dung lượng app), hãy để true
            isMinifyEnabled = false 
            isShrinkResources = false
            
            // Thêm dòng này để bản release vẫn có thể debug log nếu cần
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
