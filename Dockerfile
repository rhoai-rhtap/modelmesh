
# Build arguments
ARG SOURCE_CODE=.

FROM registry.redhat.io/ubi8/ubi-minimal@sha256:7583ca0ea52001562bd81a961da3f75222209e6192e4e413ee226cff97dbd48c AS stage

RUN ls -la ./cachi2/output
RUN ls -la ./cachi2/output/deps

# Install packages for the install script and extract archives
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y unzip jq wget

RUN cd ./cachi2/output/deps/generic && ls -l && \
    for file in *.zip; ls -l "$file" do unzip -d /root/ "$file"; done


###############################################################################
#latest tag
FROM registry.redhat.io/ubi8/openjdk-17-runtime@sha256:f86ab776ae96ff2fcb376c4107ad3e7abefbb7fae794c56eddb56770f556a061 as runtime

## Build args to be used at this step
ARG USERID=2000


USER root

RUN sed -i 's:security.provider.12=SunPKCS11:#security.provider.12=SunPKCS11:g' /usr/lib/jvm/java-17-openjdk-*/conf/security/java.security \
    && sed -i 's:#security.provider.1=SunPKCS11 ${java.home}/lib/security/nss.cfg:security.provider.12=SunPKCS11 ${java.home}/lib/security/nss.cfg:g' /usr/lib/jvm/java-17-openjdk-*/conf/security/java.security

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
    echo "${CI_CONTAINER_VERSION}" > /opt/kserve/mmesh/build-version

EXPOSE 8080

# Run as non-root user by default, to allow runAsNonRoot:true without runAsUser
USER ${USERID}


# The command to run by default when the container is first launched
CMD ["sh", "-c", "exec /opt/kserve/mmesh/start.sh"]
