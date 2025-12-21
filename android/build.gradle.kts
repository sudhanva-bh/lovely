// 1. ADD THIS BUILDSCRIPT BLOCK AT THE TOP
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // The Google Services plugin class path
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// 2. The rest of your existing file follows below...
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
