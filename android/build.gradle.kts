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

// Some transitive plugins still declare sourceCompatibility = VERSION_1_8
// in their own build files. On JDK 11+ the compiler emits cosmetic
// "source/target value 8 is obsolete" warnings for those — three lines per
// build that mean nothing. Suppress just that warning category. We don't
// override the plugins' actual source/target levels (forcing them to 11
// would technically work but introduces a non-zero risk against plugins
// that genuinely target Java 8).
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
