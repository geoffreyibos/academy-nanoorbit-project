plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21" apply false
    id("org.jetbrains.kotlin.kapt") version "2.0.21" apply false
}

val isWindows = System.getProperty("os.name").startsWith("Windows", ignoreCase = true)
val repoRoot = rootDir.parentFile?.parentFile
val startLocalApiScript = repoRoot?.resolve("scripts/start-nanoorbit-local-api.ps1")

val startLocalApi by tasks.registering(Exec::class) {
    group = "nanoorbit"
    description = "Demarre l'API locale NanoOrbit avant le build Android."

    onlyIf {
        isWindows && startLocalApiScript?.isFile == true
    }

    workingDir = repoRoot
    commandLine(
        "powershell",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        startLocalApiScript!!.absolutePath
    )
}
