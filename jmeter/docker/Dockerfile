FROM eclipse-temurin:11-jre

ARG JMETER_VERSION=5.6.3
ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV PATH=${JMETER_HOME}/bin:${PATH}

RUN apt-get update && apt-get install -y wget unzip && rm -rf /var/lib/apt/lists/* &&     wget -q https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip -O /tmp/jmeter.zip &&     unzip -q /tmp/jmeter.zip -d /opt && rm /tmp/jmeter.zip

WORKDIR /jmeter
ENTRYPOINT ["jmeter"]