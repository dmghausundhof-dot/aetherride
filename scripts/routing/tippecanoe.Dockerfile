FROM ubuntu:24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends make gcc g++ libsqlite3-dev zlib1g-dev git ca-certificates \
 && git clone --depth 1 https://github.com/felt/tippecanoe.git /src \
 && make -C /src -j$(nproc) \
 && make -C /src install \
 && apt-get purge -y gcc g++ make git \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /src
WORKDIR /data
ENTRYPOINT ["tippecanoe"]
