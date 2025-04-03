# Partly based on https://github.com/henryiii/docker-pyodide-build/

FROM python:3.12.1

SHELL ["/bin/bash", "-c"]

ENV BUILDER_DIR=/opt/pyodide_builder
WORKDIR ${BUILDER_DIR}

RUN python3 -m venv venv-host \
	&& source venv-host/bin/activate \
	&& pip install rich \
	&& pip install pyodide-build \
	&& pyodide config list \
	&& EMSCRIPTEN_VERSION=$(pyodide config get emscripten_version) \
	&& git clone https://github.com/emscripten-core/emsdk.git \
	&& ./emsdk/emsdk install $EMSCRIPTEN_VERSION \
	&& ./emsdk/emsdk activate $EMSCRIPTEN_VERSION \
	&& source ./emsdk/emsdk_env.sh \
	&& pyodide venv venv-pyodide \
	&& deactivate

RUN apt-get update && apt-get install -y \
	build-essential

ENV BUILDER_EMSDK_DIR=${BUILDER_DIR}/emsdk
COPY ./pyodide_builder/autorun.sh .
COPY ./pyodide_builder/entrypoint.sh .

ENTRYPOINT ["/opt/pyodide_builder/entrypoint.sh"]
CMD ["/bin/bash"]
