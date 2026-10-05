allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use a JDK supported by the Android/Gradle toolchain for project compilation.
// This does not change the JDK used to run Gradle itself.
subprojects {
    plugins.withId("java") {
        extensions.configure<org.gradle.api.plugins.JavaPluginExtension> {
            toolchain.languageVersion.set(
                org.gradle.jvm.toolchain.JavaLanguageVersion.of(17)
            )
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
