ARG CROSS_BASE_IMAGE
FROM $CROSS_BASE_IMAGE

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
        python3-pip \
        wget


RUN echo "[constants]\n\
target_runner = `(python3 -c "print('${CROSS_TARGET_RUNNER}'.split())")`\n\
[binaries]\n\
 c = '${CROSS_TOOLCHAIN_PREFIX}gcc${CROSS_TOOLCHAIN_SUFFIX}'\n\
 cpp = '${CROSS_TOOLCHAIN_PREFIX}g++'\n\
 ar = '${CROSS_TOOLCHAIN_PREFIX}ar'\n\
 strip = '${CROSS_TOOLCHAIN_PREFIX}strip'\n\
 pkg-config = '${PKG_CONFIG_PATH}'\n\
 exe_wrapper = target_runner\n\
 [properties]\n\
 sys_root = '${CROSS_SYSROOT}'\n\
  cmake_toolchain_file = '/opt/toolchain.cmake'\n\
 [host_machine]\n\
 system = 'linux'\n\
 cpu_family = '${CROSS_CMAKE_SYSTEM_PROCESSOR}'\n\
 cpu = '${CROSS_CMAKE_SYSTEM_PROCESSOR}'\n\
 endian = 'little'" > /opt/meson_toolchain.txt


ENV MESON_ARGS="--cross-file /opt/meson_toolchain.txt"
# mediasoup-rust needs CXX environment variables to link C++ standard libraries.
ENV CXX="${CROSS_TOOLCHAIN_PREFIX}g++"
ENV CC="${CROSS_TOOLCHAIN_PREFIX}gcc${CROSS_TOOLCHAIN_SUFFIX}"

