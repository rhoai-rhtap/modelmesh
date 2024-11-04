# Build arguments
ARG CI_CONTAINER_VERSION="unknown"

# Set the context to the source directory
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS stage


RUN ls -la .
RUN ls -la ..
RUN ls -la ./cachi2/output
RUN ls -la ./cachi2/output/deps
RUN ls -la ./cachi2/cachi2.env

RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y unzip jq


RUN cd ./cachi2/output/deps/generic && \
    for file in *.zip; do unzip -d /root/ "$file"; done
    
###############################################################################
FROM registry.access.redhat.com/ubi8/openjdk-17-runtime:latest as runtime

## Build args to be used at this step
ARG CI_CONTAINER_VERSION
ARG USERID=2000

LABEL com.redhat.component="odh-modelmesh-container" \
      name="managed-open-data-hub/odh-modelmesh-rhel8" \
      version="${CI_CONTAINER_VERSION}" \
      git.url="${CI_MODELMESH_UPSTREAM_URL}" \
      git.commit="${CI_MODELMESH_UPSTREAM_COMMIT}" \
      summary="odh-modelmesh" \
      io.openshift.expose-services="" \
      io.k8s.display-name="odh-modelmesh" \
      maintainer="['managed-open-data-hub@redhat.com']" \
      description="Modelmesh is a distributed LRU cache for serving runtime models" \
      com.redhat.license_terms="https://www.redhat.com/licenses/Red_Hat_Standard_EULA_20191108.pdf"

USER root

RUN sed -i 's:security.provider.12=SunPKCS11:#security.provider.12=SunPKCS11:g' /usr/lib/jvm/java-17-openjdk-*/conf/security/java.security \
    && sed -i 's:#security.provider.1=SunPKCS11 ${java.home}/lib/security/nss.cfg:security.provider.12=SunPKCS11 ${java.home}/lib/security/nss.cfg:g' /usr/lib/jvm/java-17-openjdk-*/conf/security/java.security

ENV JAVA_HOME=/usr/lib/jvm/jre-17-openjdk


COPY --from=stage root/target/dockerhome/ /opt/kserve/mmesh/
COPY --from=stage root/target/dockerhome/version /etc/modelmesh-version


# Make this the current directory when starting the container
WORKDIR /opt/kserve/mmesh

RUN microdnf install shadow-utils
RUN useradd -c "Application User" -U -u ${USERID} -m app && \
    chown -R app:0 /home/app && \
    chmod g+w /etc/passwd && \
    ln -s /opt/kserve/mmesh /opt/kserve/tas && \
    mkdir -p log && \
    chown -R app:0 . && \
    chmod -R 771 . && chmod 775 *.sh *.py && \
    echo "${CI_CONTAINER_VERSION}" > /opt/kserve/mmesh/build-version && \
    sed -i 's/security.useSystemPropertiesFile=true/security.useSystemPropertiesFile=false/g' $JAVA_HOME/conf/security/java.security

EXPOSE 8080

# Run as non-root user by default, to allow runAsNonRoot:true without runAsUser
USER ${USERID}
#RUN echo "Files to download: $PNC_FILES_JSON"
#ARG PNC_ZIP_FILES
#ARG PNC_POM_FILES


# The command to run by default when the container is first launched
CMD ["sh", "-c", "exec /opt/kserve/mmesh/start.sh"]
