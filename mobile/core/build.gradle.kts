plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.kotlinSerialization)
}

kotlin {
    jvm() // Add JVM target for testing

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
    }
}

// Gradle task alias for assembling Apple framework
tasks.register("assembleAppleFramework") {
    dependsOn("assembleXCFramework")
    description = "Assembles XCFramework for Apple platforms"
    group = "build"
}