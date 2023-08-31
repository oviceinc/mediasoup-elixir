ARG CROSS_BASE_IMAGE
FROM $CROSS_BASE_IMAGE

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
        python3-pip \
        wget


RUN printf '%s\n' "[binaries]"\
 "c = '${CROSS_TOOLCHAIN_PREFIX}gcc${CROSS_TOOLCHAIN_SUFFIX}'" \
 "cpp = '${CROSS_TOOLCHAIN_PREFIX}g++'" \
 "ar = '${CROSS_TOOLCHAIN_PREFIX}ar'" \
 "strip = '${CROSS_TOOLCHAIN_PREFIX}strip'" \
 "pkg-config = '${PKG_CONFIG_PATH}'" \
 "[properties]" \
  "sys_root = '${CROSS_SYSROOT}'" \
  "cmake_toolchain_file = '/opt/toolchain.cmake'" \
 "[host_machine]" \
 "system = 'linux'" \
 "cpu_family = '${CROSS_CMAKE_SYSTEM_PROCESSOR}'" \
 "cpu = '${CROSS_CMAKE_SYSTEM_PROCESSOR}'" \
 "endian = 'little'" \
 > /opt/meson_toolchain.txt

ENV MESON_ARGS="--cross-file /opt/meson_toolchain.txt"
# mediasoup-rust needs CXX environment variables to link C++ standard libraries.
ENV CXX="${CROSS_TOOLCHAIN_PREFIX}g++"
ENV CC="${CROSS_TOOLCHAIN_PREFIX}gcc${CROSS_TOOLCHAIN_SUFFIX}"

