package com.pms.performance.util;

import com.pms.performance.simulation.DoctorLoadSimulation;
import lombok.Getter;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class SimulationConfig {

    private static final Properties props = loadProperties();

    @Getter
    private static final String baseUrl = props.getProperty("baseUrl", "http://localhost:9082/v1/");

    @Getter
    private static final int users = Integer.parseInt(props.getProperty("users", "100"));

    @Getter
    private static final int durationMinutes = Integer.parseInt(props.getProperty("durationMinutes", "5"));

    private static Properties loadProperties() {
        Properties props = new Properties();
        try (InputStream input = DoctorLoadSimulation.class
                .getClassLoader()
                .getResourceAsStream("application.properties")) {
            if (input == null) {
                throw new RuntimeException("simulation.properties not found in resources folder!");
            }
            props.load(input);
        } catch (IOException e) {
            throw new RuntimeException("Failed to load simulation.properties", e);
        }
        return props;
    }

}
