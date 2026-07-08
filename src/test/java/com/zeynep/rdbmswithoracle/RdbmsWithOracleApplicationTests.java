package com.zeynep.rdbmswithoracle;

import org.junit.jupiter.api.Test;

class RdbmsWithOracleApplicationTests {

    @Test
    void applicationClassExists() {
        RdbmsWithOracleApplication.main(new String[] {"--spring.main.web-application-type=none", "--spring.flyway.enabled=false"});
    }

}
