// Firebase (notifications push) : le plugin google-services n'est chargé que si
// app/google-services.json est présent. Sans lui, l'application se construit et
// fonctionne normalement, notifications push désactivées.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        if (file("app/google-services.json").exists()) {
            classpath("com.google.gms:google-services:4.4.4")
        }
    }
}

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
