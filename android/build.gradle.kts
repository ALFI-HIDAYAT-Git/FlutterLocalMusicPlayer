allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    val targetProject = this
    pluginManager.withPlugin("com.android.library") {
        if (targetProject.name == "on_audio_query_android") {
            targetProject.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                namespace = "com.lucasjosino.on_audio_query"
            }
        }
        targetProject.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        if (targetProject.name == "on_audio_query_android") {
            targetProject.extensions.configure<
                com.android.build.api.variant.LibraryAndroidComponentsExtension,
            > {
                finalizeDsl { extension ->
                    extension.compileSdk = 36
                }
            }
        }
    }
    pluginManager.withPlugin("org.jetbrains.kotlin.android") {
        targetProject.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                )
            }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
