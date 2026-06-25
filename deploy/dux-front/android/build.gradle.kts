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
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid = { proj: Project ->
        proj.plugins.withId("com.android.application") {
            proj.extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
                compileSdk = 36
            }
        }
        proj.plugins.withId("com.android.library") {
            proj.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                compileSdk = 36
            }
        }
    }

    if (project.state.executed) {
        configureAndroid(project)
    } else {
        project.afterEvaluate {
            configureAndroid(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
