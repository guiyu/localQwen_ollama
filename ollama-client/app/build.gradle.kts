plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.qw.sutra"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.qw.sutra"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        // 添加 NDK 配置
        ndkVersion = "25.2.9519653"

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86")
        }

    }
    dependencies {
        implementation(project(":models"))
    }

    // 添加 jniLibs 配置
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("libs/jniLibs")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {

    // 现有依赖保持不变
    implementation("androidx.core:core-ktx:1.3.2")
    implementation("androidx.appcompat:appcompat:1.2.0")
    implementation("com.google.android.material:material:1.4.0")

    // 网络请求
    implementation("com.squareup.okhttp3:okhttp:3.12.13")  // 保持这个版本以支持 API 16
    implementation("com.squareup.okhttp3:okhttp-sse:3.12.13")  // 添加 SSE 支持
    implementation("com.google.code.gson:gson:2.8.9")

    // 生命周期组件
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.2.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.2.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.2.0")

    // 测试依赖
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.3")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.4.0")

    // 添加协程支持
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.2.0")


    // 添加 Vosk 依赖
    implementation("com.alphacephei:vosk-android:0.3.47")
    implementation("org.apache.commons:commons-io:1.3.2")

    // Vosk 必要依赖
    implementation("net.java.dev.jna:jna:5.13.0@aar")
    implementation("com.alphacephei:vosk-android:0.3.47@aar")
}