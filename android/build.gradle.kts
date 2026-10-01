allprojects {
    ext {
        set("compileSdkVersion", 36)
        set("appCompatVersion", "1.7.1")
        set("playServicesLocationVersion", "21.3.0")
    }
    repositories {
        google()
        mavenCentral()
        // [required] flutter_background_geolocation
        maven(url = "${project(":flutter_background_geolocation").projectDir}/libs")
        // [required] background_fetch
        maven(url = "${project(":background_fetch").projectDir}/libs")
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
