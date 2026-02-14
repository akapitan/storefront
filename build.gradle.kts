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

// ─── Dependency versions (also see gradle/libs.versions.toml) ─────────────────
//val jooqVersion          = libs.versions.jooq.get()
//val springModulithVersion = libs.versions.springModulith.get()
//val testcontainersVersion = libs.versions.testcontainers.get()

// ─── Dependencies ─────────────────────────────────────────────────────────────
dependencies {

    // ── Web + Thymeleaf ───────────────────────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-thymeleaf")
//    implementation("org.thymeleaf.extras:thymeleaf-extras-springsecurity6")
// Test
//    implementation(libs.spring.data.commons)

    // ── jOOQ (OSS — PostgreSQL supported) ────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-jooq")
//    implementation("org.jooq:jooq:$jooqVersion")
    // jOOQ codegen only needed at build time
    // Align jOOQ codegen artifacts to Spring Boot's BOM to avoid version mismatches.
    jooqCodegen(platform(libs.spring.boot.bom))
    jooqCodegen(libs.postgresql)
    jooqCodegen(libs.jooq.codegen)
//    jooqCodegen("org.jooq:jooq-meta:$jooqVersion")
//    jooqCodegen("org.jooq:jooq-codegen:$jooqVersion")
//    jooqCodegen("org.postgresql:postgresql")

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
//    implementation("org.springframework.modulith:spring-modulith-starter-core")
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

/*
// ─── jOOQ Code Generation ─────────────────────────────────────────────────────
//
// Run with:   ./gradlew jooqCodegen
//
// Prerequisite: a running local PostgreSQL with Flyway migrations applied.
// Tip: run `docker compose up -d db && ./gradlew flywayMigrate jooqCodegen`
//
// Generated classes land in src/main/generated/
// Commit them — they are your type-safe SQL API.
//
jooq {
    configuration {
        logging = Logging.WARN

        jdbc {
            driver   = "org.postgresql.Driver"
            url      = System.getenv("CODEGEN_DB_URL")
                       ?: "jdbc:postgresql://localhost:5432/storefront_dev"
            user     = System.getenv("CODEGEN_DB_USER")     ?: "storefront"
            password = System.getenv("CODEGEN_DB_PASSWORD") ?: "storefront"
        }

        generator {
            name = "org.jooq.codegen.JavaGenerator"

            database {
                name         = "org.jooq.meta.postgres.PostgresDatabase"
                inputSchema  = "public"
                includes     = ".*"
                excludes     = "flyway_schema_history"

                // JSONB → Jackson JsonNode
                forcedTypes.addAll(listOf(
                    ForcedType().apply {
                        userType    = "com.fasterxml.jackson.databind.JsonNode"
                        includeTypes = "JSONB"
                        includeExpression = ".*"
                        converter   = "com.storefront.shared.jooq.JsonNodeConverter"
                    },
                    ForcedType().apply {
                        name = "BIGDECIMAL"
                        includeExpression = ".*\\.(price|amount|cost|total).*"
                        includeTypes = "NUMERIC"
                    }
                ))
            }

            generate {
                isPojos                  = true
                isPojosEqualsAndHashCode = true
                isFluentSetters          = true
                isComments               = true
                isValidationAnnotations  = true
                isSpringAnnotations      = true
                isSerializablePojos      = true  // Redis-cacheable
                isImmutablePojos         = false
            }

            target {
                packageName = "com.storefront.jooq"
                directory   = "src/main/generated"
                encoding    = "UTF-8"
                isClean     = true
            }
        }
    }
}
*/

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
