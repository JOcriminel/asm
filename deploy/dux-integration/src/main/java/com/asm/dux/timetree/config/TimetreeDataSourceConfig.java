package com.asm.dux.timetree.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import javax.sql.DataSource;
import liquibase.integration.spring.SpringLiquibase;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.asm.dux.timetree.repository",
        entityManagerFactoryRef = "timertreeEntityManager",
        transactionManagerRef = "timertreeTransactionManager"
)
public class TimetreeDataSourceConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.timetree")
    public DataSourceProperties timertreeDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = "timertreeDataSource")
    public DataSource timertreeDataSource() {
        DataSourceProperties properties = timertreeDataSourceProperties();
        return properties.initializeDataSourceBuilder()
                .type(HikariDataSource.class)
                .build();
    }

    @Bean
    public SpringLiquibase timetreeLiquibase(@Qualifier("timertreeDataSource") DataSource dataSource) {
        SpringLiquibase liquibase = new SpringLiquibase();
        liquibase.setDataSource(dataSource);
        liquibase.setChangeLog("classpath:/db/changelog/master.xml");
        liquibase.setDefaultSchema("dbo");
        return liquibase;
    }

    @Bean(name = "timertreeEntityManager")
    public LocalContainerEntityManagerFactoryBean timertreeEntityManager(@Qualifier("timertreeDataSource") DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(dataSource);
        em.setPackagesToScan("com.asm.dux.timetree.domain");
        em.setJpaVendorAdapter(new HibernateJpaVendorAdapter());
        Map<String, Object> jpaProperties = new HashMap<>();
        jpaProperties.put("hibernate.hbm2ddl.auto", "none");
        jpaProperties.put("hibernate.dialect", "org.hibernate.dialect.SQLServer2012Dialect");
        em.setJpaPropertyMap(jpaProperties);
        return em;
    }

    @Bean(name = "timertreeTransactionManager")
    public PlatformTransactionManager timertreeTransactionManager(@Qualifier("timertreeEntityManager") LocalContainerEntityManagerFactoryBean entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory.getObject());
    }
}
