allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val sharedBuild = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(sharedBuild)
subprojects {
    layout.buildDirectory.set(sharedBuild.dir(name))
}
subprojects {
    evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
