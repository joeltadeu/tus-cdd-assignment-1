package com.pms.performance.simulation;

import com.pms.performance.util.DoctorJsonFactory;
import com.pms.performance.util.SimulationConfig;
import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.HttpProtocolBuilder;

import java.time.Duration;
import java.util.*;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.http;
import static io.gatling.javaapi.http.HttpDsl.status;

public class DoctorLoadSimulation extends Simulation {

    ChainBuilder getDoctorById = exec(
            http("Get doctor by Id")
                    .get("doctors/#{doctorId}")
                    .check(status().is(200)),
            pause(1)
    );

    ChainBuilder getAllDoctors = exec(
            http("Get all doctors").get("doctors")
                    .check(status().is(200)),
            pause(1)
    );

    ChainBuilder createDoctor = exec(session -> {
        // put generated JSON into session
        String doctorJson = DoctorJsonFactory.generateJson();
        return session.set("doctorPayload", doctorJson);
    }).exec(
            http("Create doctor")
                    .post("doctors")
                    .header("Content-Type", "application/json")
                    .body(StringBody("#{doctorPayload}")).asJson()
                    .check(status().is(201))
                    .check(jsonPath("$.id").saveAs("doctorId"))
    ).pause(1);

    HttpProtocolBuilder httpProtocol =
            http.baseUrl(SimulationConfig.getBaseUrl())
                    .header("Accept", "application/json");

    ScenarioBuilder scenario = scenario("Performance Load Simulation")
            .exec(getAllDoctors)
            .pause(5)
            .exec(createDoctor)
            .pause(5)
            .exec(getDoctorById)
            .pause(5)
            .exec(getAllDoctors);

    {
        List<ClosedInjectionStep> steps = new ArrayList<>();
        steps.add(rampConcurrentUsers(0).to(SimulationConfig.getUsers()).during(60));
        steps.add(constantConcurrentUsers(SimulationConfig.getUsers()).during(Duration.ofMinutes(SimulationConfig.getDurationMinutes())));
        setUp(
                scenario.injectClosed(steps)
        ).protocols(httpProtocol);
    }
}
