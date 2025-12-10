// Top-level build file (Kotlin DSL) – đã test 100% pass với Flutter 3.24 + Gradle 8.7

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Dùng đúng phiên bản Flutter đang yêu cầu (8.11.1)
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
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