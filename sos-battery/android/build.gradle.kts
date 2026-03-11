// Top-level build file – Flutter chuẩn Kotlin DSL mới nhất

plugins {
    // KHÔNG chỉ định version cho com.android.application và kotlin-android
    // Để Flutter tự resolve version phù hợp (tránh conflict như lỗi của bạn)
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
    
    // Chỉ google-services cần version cụ thể
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Đổi thư mục build ra ngoài (giữ nguyên như bạn đang dùng)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}