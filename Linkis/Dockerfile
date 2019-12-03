FROM openjdk:8u232-jdk 
ADD wedatasphere-linkis-0.9.1-dist-spark2.0-2.2/share/linkis/module/module.zip /module.zip

RUN mkdir -p /opt && unzip module.zip -d /opt && rm -rf module.zip
