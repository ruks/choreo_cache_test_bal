
# FROM choreowbcuserappsescargot.azurecr.io/ballerina-central/v2/base:latest AS ballerina-tools-build
FROM ballerina/ballerina:2201.12.4 AS ballerina-tools-build
LABEL maintainer "ballerina.io"

USER root

COPY . /home/work-dir/choreo_cache_test
WORKDIR /home/work-dir/choreo_cache_test

RUN bal build

FROM eclipse-temurin:17-jre-alpine

RUN mkdir -p /work-dir \
    && addgroup troupe \
    && adduser -S -s /bin/bash -g 'ballerina' -G troupe -D ballerina \
    && apk upgrade \
    && chown -R ballerina:troupe /work-dir

USER ballerina

WORKDIR /home/work-dir/

COPY --from=ballerina-tools-build /home/work-dir/choreo_cache_test/target/bin/choreo_cache_test.jar /home/work-dir/

EXPOSE 2020

ENV JAVA_TOOL_OPTIONS "-XX:+UseContainerSupport -XX:MaxRAMPercentage=80.0 -XX:TieredStopAtLevel=1"

USER 10500
CMD [ "java", "-jar", "choreo_cache_test.jar" ]
