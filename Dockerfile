FROM docker:19.03.1

RUN apk --update add \
  python \
  py-pip \
  jq \
  bash \
  curl \
  wget \
  && pip install awscli \
  && apk del py-pip \
  && rm -rf /var/cache/apk/*

RUN curl -fL https://getcli.jfrog.io | sh && \
  mv jfrog /usr/local/bin && \
  chmod a+x /usr/local/bin/jfrog

ENV PACKER_VERSION=1.4.5

RUN wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
  unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
  mv packer /usr/local/bin && \
  chmod a+x /usr/local/bin/packer

ENV TERRAFORM_VERSION=0.12.13

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && mv terraform /usr/local/bin \
  && chmod a+x /usr/local/bin/terraform




ENV KUBECTL_VERSION="v1.13.4"

ENV HELM_VERSION="v2.13.0"

RUN apk add --update ca-certificates bash gnupg jq py-pip wget git \
  && apk add --update -t deps curl gettext \
  && pip install awscli \
  && rm -rf /var/cache/apk/*

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
  & curl -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.3.0/heptio-authenticator-aws_0.3.0_linux_amd64 -o /usr/local/bin/aws-iam-authenticator \
  & wait \
  && chmod +x /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/aws-iam-authenticator \
  && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm

#Install java
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk add --no-cache --virtual .build-deps curl binutils \
  && GLIBC_VER="2.29-r0" \
  && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
  && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" \
  && GCC_LIBS_SHA256="91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08" \
  && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" \
  && ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 \
  && curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
  && SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" \
  && echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - \
  && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk \
  && apk add --no-cache /tmp/glibc-${GLIBC_VER}.apk \
  && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk \
  && apk add --no-cache /tmp/glibc-bin-${GLIBC_VER}.apk \
  && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk \
  && apk add --no-cache /tmp/glibc-i18n-${GLIBC_VER}.apk \
  && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
  && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
  && curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
  && echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - \
  && mkdir /tmp/gcc \
  && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
  && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
  && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
  && curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz \
  && echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - \
  && mkdir /tmp/libz \
  && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
  && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
  && apk del --purge .build-deps glibc-i18n \
  && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_VERSION jdk8u

RUN set -eux; \
  apk add --no-cache --virtual .fetch-deps curl; \
  ARCH="$(apk --print-arch)"; \
  case "${ARCH}" in \
  aarch64|arm64) \
  ESUM='6e8b6b037148cf20a284b5b257ec7bfdf9cc31ccc87778d0dfd95a2fddf228d4'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.2%2B7/OpenJDK15U-jdk_aarch64_linux_hotspot_15.0.2_7.tar.gz'; \
  ;; \
  armhf) \
  ESUM='6e8b6b037148cf20a284b5b257ec7bfdf9cc31ccc87778d0dfd95a2fddf228d4'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.2%2B7/OpenJDK15U-jdk_arm_linux_hotspot_15.0.2_7.tar.gz'; \
  ;; \
  ppc64el|ppc64le) \
  ESUM='ff39c0380224e419d940382c4d651cb1e6297a794854e0cc459c1fd4973b3368'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.2%2B7/OpenJDK15U-jdk_ppc64_aix_hotspot_15.0.2_7.tar.gz'; \
  ;; \
  s390x) \
  ESUM='7dc35a8a4ba1ccf6cfe96fcf26e09ed936f1802ca668ca6bf708e2392c35ab6a'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.2%2B7/OpenJDK15U-jdk_s390x_linux_hotspot_15.0.2_7.tar.gz'; \
  ;; \
  amd64|x86_64) \
  ESUM='94f20ca8ea97773571492e622563883b8869438a015d02df6028180dd9acc24d'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.2%2B7/OpenJDK15U-jdk_x64_linux_hotspot_15.0.2_7.tar.gz'; \
  ;; \
  *) \
  echo "Unsupported arch: ${ARCH}"; \
  exit 1; \
  ;; \
  esac; \
  curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
  echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
  mkdir -p /opt/java/openjdk; \
  cd /opt/java/openjdk; \
  tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
  apk del --purge .fetch-deps; \
  rm -rf /var/cache/apk/*; \
  rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
  PATH="/opt/java/openjdk/bin:$PATH"


# Install gradle
ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 6.9.2

ARG GRADLE_DOWNLOAD_SHA256=8b356fd8702d5ffa2e066ed0be45a023a779bba4dd1a68fd11bc2a6bdc981e8f
RUN set -o errexit -o nounset \
  && echo "Installing build dependencies" \
  && apk add --no-cache --virtual .build-deps \
  ca-certificates \
  openssl \
  unzip \
  \
  && echo "Downloading Gradle" \
  && wget -O gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
  \
  && echo "Checking download hash" \
  && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum -c - \
  \
  && echo "Installing Gradle" \
  && unzip gradle.zip \
  && rm gradle.zip \
  && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
  && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
  \
  && apk del .build-deps \
  \
  && echo "Adding gradle user and group" \
  && addgroup -S -g 1000 gradle \
  && adduser -D -S -G gradle -u 1000 -s /bin/bash gradle \
  && mkdir /home/gradle/.gradle \
  && chown -R gradle:gradle /home/gradle \
  \
  && echo "Symlinking root Gradle cache to gradle Gradle cache" \
  && ln -s /home/gradle/.gradle /root/.gradle

# RUN usermod -aG docker gradle

RUN curl -L https://github.com/Praqma/helmsman/releases/download/v1.8.0/helmsman_1.8.0_linux_amd64.tar.gz | tar zx \
  && mv helmsman /usr/local/bin/helmsman \
  && chmod +x /usr/local/bin/helmsman


ENV LEIN_ROOT 1
ENV LEIN_VERSION 2.9.8

RUN apk add --no-cache wget ca-certificates bash 
RUN wget -q "https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein" -O /usr/local/bin/lein && \
  chmod 0755 /usr/local/bin/lein && \
  lein && \
  # Do clean up
  rm -rf /tmp/*

# Create Gradle volume
USER gradle
VOLUME "/home/gradle/.gradle"
WORKDIR /home/gradle

# Install Helm plugins
RUN helm init --client-only  --skip-refresh && helm repo rm stable && helm repo add stable https://charts.helm.sh/stable
RUN helm plugin install https://github.com/viglesiasce/helm-gcs.git
RUN helm plugin install https://github.com/databus23/helm-diff
RUN helm plugin install https://github.com/chartmuseum/helm-push
# RUN helm plugin install https://github.com/futuresimple/helm-secrets

RUN set -o errexit -o nounset \
  && echo "Testing Gradle installation" \
  && gradle --version