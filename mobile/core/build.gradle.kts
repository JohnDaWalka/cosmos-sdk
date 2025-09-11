plugins {
    kotlin("multiplatform") version "2.0.21"
    // id("com.android.library") version "8.3.2" // Temporarily disabled 
    kotlin("plugin.serialization") version "2.0.21"
}

kotlin {
    // androidTarget {  // Temporarily disabled
    //     compilations.all {
    //         kotlinOptions {
    //             jvmTarget = "21"
    //         }
    //     }
    // }
    
    jvm() // JVM target for testing

    // Apple platforms
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    
    tvosX64()
    tvosArm64()
    tvosSimulatorArm64()
    
    watchosX64()
    watchosArm32()
    watchosArm64()
    watchosSimulatorArm64()
    
    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.kotlinx.datetime)
        }
        
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
        
        // androidMain.dependencies {  // Temporarily disabled
        //     implementation(libs.kotlinx.coroutines.core)
        // }
    }
}

// android {  // Temporarily disabled
//     namespace = "com.maurofanelli.app.core"
//     compileSdk = 34
//
//     defaultConfig {
//         minSdk = 24
//     }
//     
//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_21
//         targetCompatibility = JavaVersion.VERSION_21
//     }
// }

// Gradle task alias for assembling Apple framework
tasks.register("assembleAppleFramework") {
    dependsOn("assembleXCFramework")
    description = "Assembles XCFramework for Apple platforms"
    group = "build"
}