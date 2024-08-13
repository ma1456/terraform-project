FROM openjdk:21-jdk-slim
RUN mkdir -p /spring-boot-3-rest-api-example-master/
WORKDIR /spring-boot-3-rest-api-example-master
COPY spring-boot-3-rest-api-example-master .
EXPOSE 8080
#RUN groupadd -r appusergroup && useradd -r -g appusergroup appuser
#RUN chown -R appuser:appusergroup /spring-boot-3-rest-api-example-master
#USER appuser
CMD ["java", "-jar", "/spring-boot-3-rest-api-example-master/target/spring-boot-3-rest-api-example-master-0.0.1-SNAPSHOT.jar"]