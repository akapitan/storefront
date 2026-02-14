plugins {
    java
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.spring.dependency.management)
    alias(libs.plugins.jooq.docker)
}

group = "com.storefront"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

// ─── Dependencies ─────────────────────────────────────────────────────────────
dependencies {

    // ── Web + JTE ─────────────────────────────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("gg.jte:jte-spring-boot-starter-3:3.1.12")
    implementation("gg.jte:jte:3.1.12")

    // ── jOOQ (OSS — PostgreSQL supported) ────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-jooq")
    // jOOQ codegen only needed at build time
    // Align jOOQ codegen artifacts to Spring Boot's BOM to avoid version mismatches.
    jooqCodegen(platform(libs.spring.boot.bom))
    jooqCodegen(libs.postgresql)
    jooqCodegen(libs.jooq.codegen)

    // ── Database ─────────────────────────────────────────────────────────────
    runtimeOnly("org.postgresql:postgresql")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // ── Caching: Redis (L2) + Caffeine (L1) ──────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-cache")
    implementation("com.github.ben-manes.caffeine:caffeine")

    // ── Security + Session ────────────────────────────────────────────────────
//    implementation("org.springframework.boot:spring-boot-starter-security")
//    implementation("org.springframework.session:spring-session-data-redis")

    // ── Spring Modulith ───────────────────────────────────────────────────────
    implementation("org.springframework.modulith:spring-modulith-starter-core:2.0.2")
    // Produces module documentation (C4/PlantUML) via tests
    testImplementation("org.springframework.modulith:spring-modulith-starter-test:2.0.2")

    // ── Observability ─────────────────────────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("io.micrometer:micrometer-registry-cloudwatch2")

    // ── Utilities ─────────────────────────────────────────────────────────────
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    // ── Testing ───────────────────────────────────────────────────────────────
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    implementation(libs.testcontainers.junit.jupiter)
    implementation(libs.testcontainers.postgresql)
}

// Include generated sources in compilation
sourceSets {
    main {
        java {
            srcDir("src/main/generated")
        }
    }
}

// ─── Test configuration ───────────────────────────────────────────────────────
tasks.withType<Test> {
    useJUnitPlatform()
    // Pass DB env vars to tests (Testcontainers overrides at runtime)
    jvmArgs("-XX:+EnableDynamicAgentLoading")
}

// ─── Compiler flags ───────────────────────────────────────────────────────────
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(
        listOf(
            "-parameters",          // preserve method parameter names (Spring MVC needs this)
            "-Xlint:unchecked"
        )
    )
}

// ─── Convenience tasks ────────────────────────────────────────────────────────

// ./gradlew bootRunDev  — starts app with 'dev' profile
tasks.register<JavaExec>("bootRunDev") {
    group = "application"
    description = "Run with Spring profile 'dev' (verbose SQL logging, Thymeleaf cache off)"
    classpath = sourceSets.main.get().runtimeClasspath
    mainClass = "com.storefront.StorefrontApplication"
    systemProperty("spring.profiles.active", "dev")
}


tasks {
    generateJooqClasses {
        basePackageName.set("com.storefront.jooq")
        outputDirectory.set(project.layout.projectDirectory.dir("src/generated/java"))
        includeFlywayTable.set(false)
    }
}
