FROM eclipse-temurin:17-jdk

RUN mkdir /opt/scratch

# Install git, so we can sparse clone some tools
# Technically, we could just wget the tarballs from GitHub,
# but some of these are _massive_
RUN apt-get update && apt-get install -y \
	git \
	unzip

ENV intellij_path="/opt/JetBrains/intellij-community"
RUN mkdir -p ${intellij_path}
WORKDIR ${intellij_path}
RUN <<EOF
git clone --filter=blob:none --no-checkout --depth 1 --branch master --sparse https://github.com/JetBrains/intellij-community .
# aka fernflower
git sparse-checkout add plugins/java-decompiler/engine
git checkout
EOF
WORKDIR ${intellij_path}/plugins/java-decompiler/engine
RUN ./gradlew build
RUN cp ./build/libs/fernflower.jar /opt/scratch/

WORKDIR /opt/scratch

# Vineflower
# https://github.com/Vineflower/vineflower/releases/tag/1.10.1
RUN wget -O vineflower.jar https://github.com/Vineflower/vineflower/releases/download/1.10.1/vineflower-1.10.1.jar

# JADX (APK DEX to JAR)
RUN wget -O jadx.zip https://github.com/skylot/jadx/releases/download/v1.5.1/jadx-1.5.1.zip
RUN unzip -q jadx.zip -d jadx
RUN rm -rf jadx.zip
# Add bin to PATH
ENV PATH="/opt/scratch/jadx/bin:$PATH"

# Copy over local scripts as last step
COPY ./java_playground/*.sh .
COPY ./docker-entrypoint.sh .
RUN chmod +x ./docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD [ "/bin/bash", "init.sh" ]
