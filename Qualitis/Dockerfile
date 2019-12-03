FROM gradle:4.9-jdk8-slim AS build

ARG version

RUN git clone https://github.com/WeBankFinTech/Qualitis/releases/tag/release-${version} Qualitis

RUN cd Qualitis && gradle clean distZip



