FROM eclipse-temurin:17-jdk-jammy as custom-builder
COPY ./custom-providers /custom-providers
WORKDIR /custom-providers
RUN ./gradlew clean jar

FROM quay.io/keycloak/keycloak:latest as builder
COPY --from=custom-builder custom-providers/build/libs/custom-providers-1.0-SNAPSHOT.jar opt/keycloak/providers/custom-providers-1.0-SNAPSHOT.jar

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
#ENV KC_DB=postgres
COPY conf/cache-ispn.xml /opt/keycloak/conf/cache-ispn.xml
WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
#RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# change these values to point to a running postgres instance
ENV KC_METRICS_ENABLED=true
ENV KC_CACHE_CONFIG_FILE=cache-ispn.xml
#ENV KC_DB=postgres
#ENV KC_DB_URL=<DBURL>
#ENV KC_DB_USERNAME=<DBUSERNAME>
#ENV KC_DB_PASSWORD=<DBPASSWORD>
#ENV KC_HOSTNAME=localhost
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]