
mvn gatling:test -Dgatling.simulationClass=com.pms.performance.simulation.DoctorLoadSimulation



mvn gatling:test -Dgatling.simulationClass=com.pms.performance.simulation.DoctorLoadSimulation \
-DbaseUrl=http://ec2-3-248-255-253.eu-west-1.compute.amazonaws.com:9082/v1/ \
-Dusers=300 \
-DdurationMinutes=10