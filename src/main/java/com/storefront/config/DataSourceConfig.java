package com.storefront.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.jooq.DSLContext;
import org.jooq.SQLDialect;
import org.jooq.impl.DSL;
import org.jooq.impl.DefaultConfiguration;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.sql.DataSource;
import java.util.Map;

/**
 * DataSource Routing Configuration
 * ══════════════════════════════════
 *
 * Provides two DataSources and two DSLContexts:
 *
 *   primaryDsl    → RDS Primary   (writes + transactional reads)
 *   readOnlyDsl   → RDS Replica   (read-heavy queries: browse, search, listing)
 *
 * Usage in repositories:
 *
 *   @Autowired DSLContext primaryDsl;       // for writes
 *   @Autowired @Qualifier("readOnlyDsl") DSLContext readOnlyDsl;  // for reads
 *
 * The RoutingDataSource automatically routes Spring @Transactional(readOnly=true)
 * to the replica — so you can also just annotate your service methods correctly
 * and let routing happen transparently.
 */
@Configuration
public class DataSourceConfig {

    // ─── Primary DataSource (writes) ──────────────────────────────────────────

    @Bean
    @ConfigurationProperties(prefix = "datasource.primary")
    public HikariConfig primaryHikariConfig() {
        HikariConfig config = new HikariConfig();
        config.setPoolName("primary-pool");
        config.setMaximumPoolSize(20);
        config.setMinimumIdle(5);
        config.setConnectionTimeout(3000);   // 3s — fail fast
        config.setIdleTimeout(600_000);
        config.setMaxLifetime(1_800_000);
        config.setKeepaliveTime(30_000);
        // PostgreSQL-specific performance settings
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("reWriteBatchedInserts", "true"); // bulk inserts
        return config;
    }

    @Bean("primaryDataSource")
    @Primary
    public DataSource primaryDataSource(HikariConfig primaryHikariConfig) {
        return new HikariDataSource(primaryHikariConfig);
    }

    // ─── Read Replica DataSource ───────────────────────────────────────────────

    @Bean
    @ConfigurationProperties(prefix = "datasource.replica")
    public HikariConfig replicaHikariConfig() {
        HikariConfig config = new HikariConfig();
        config.setPoolName("replica-pool");
        config.setMaximumPoolSize(30);   // replicas handle more read concurrency
        config.setMinimumIdle(5);
        config.setConnectionTimeout(3000);
        config.setReadOnly(true);        // enforce read-only at connection level
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        return config;
    }

    @Bean("replicaDataSource")
    public DataSource replicaDataSource(HikariConfig replicaHikariConfig) {
        return new HikariDataSource(replicaHikariConfig);
    }

    // ─── Routing DataSource (used by Spring @Transactional) ───────────────────

    /**
     * Automatically routes to replica when the current transaction is read-only.
     * Annotate your service methods with @Transactional(readOnly = true) to route
     * to the replica transparently.
     */
    @Bean("routingDataSource")
    public DataSource routingDataSource(
            @Qualifier("primaryDataSource") DataSource primary,
            @Qualifier("replicaDataSource") DataSource replica) {

        AbstractRoutingDataSource routing = new AbstractRoutingDataSource() {
            @Override
            protected Object determineCurrentLookupKey() {
                boolean isReadOnly = TransactionSynchronizationManager.isCurrentTransactionReadOnly();
                return isReadOnly ? "replica" : "primary";
            }
        };

        routing.setTargetDataSources(Map.of("primary", primary, "replica", replica));
        routing.setDefaultTargetDataSource(primary);
        routing.afterPropertiesSet();
        return routing;
    }

    // ─── jOOQ DSLContext Beans ─────────────────────────────────────────────────

    /**
     * Primary DSLContext — use for all writes and transactional operations.
     * This is the @Primary bean, so @Autowired DSLContext injects this by default.
     */
    @Bean
    @Primary
    public DSLContext primaryDsl(@Qualifier("primaryDataSource") DataSource primaryDataSource) {
        return buildDslContext(primaryDataSource);
    }

    /**
     * Read-only DSLContext — use explicitly for read-heavy queries that
     * should hit the replica (product browsing, search, category listing).
     *
     * Usage: @Qualifier("readOnlyDsl") DSLContext readOnlyDsl
     */
    @Bean("readOnlyDsl")
    public DSLContext readOnlyDsl(@Qualifier("replicaDataSource") DataSource replicaDataSource) {
        return buildDslContext(replicaDataSource);
    }

    private DSLContext buildDslContext(DataSource dataSource) {
        DefaultConfiguration config = new DefaultConfiguration();
        config.setDataSource(dataSource);
        config.setSQLDialect(SQLDialect.POSTGRES);

        // Settings for production performance
        config.settings()
              .withRenderSchema(false)             // don't prefix every query with "public."
              .withReturnAllOnUpdatableRecord(false) // don't SELECT after every UPDATE
              .withQueryTimeout(10);               // 10s query timeout — fail fast

        return DSL.using(config);
    }
}
