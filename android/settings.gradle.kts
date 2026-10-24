pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}

// The SDK comes from the private Cloudsmith repository. Put your entitlement token in
// ~/.gradle/gradle.properties (never in this repo):
//   cloudsmithToken=<entitlement token>
// Replace ORG/REPO with the slugs you were given.
val cloudsmithToken = providers.gradleProperty("cloudsmithToken").orNull
  ?: error("Set cloudsmithToken in ~/.gradle/gradle.properties (see README)")

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
    maven {
      url = uri("https://dl.cloudsmith.io/basic/ORG/REPO/maven/")
      credentials {
        username = "token"
        password = cloudsmithToken
      }
      content { includeGroup("mn.ekyc") }
    }
  }
}

rootProject.name = "LivenessExample"
include(":app")
