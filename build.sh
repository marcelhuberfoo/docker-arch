#!/bin/bash

set -e

DATETAG=$(date +"%Y%m%d")
KERNELTAG=$(pacman -Q linux | cut -d' ' -f2)
IMGTAG=${DATETAG}-${KERNELTAG}

# remove any existing root filesystem from the repo history
git rm -f arch-rootfs*.tar.xz || true

# build an updated root filesystem
sudo ./mkimage-arch.sh ${IMGTAG}

# update the Dockerfile with the latest build "number"
sed "s/TAG/${IMGTAG}/" Dockerfile.tpl > Dockerfile
sudo chown $(id --user):$(id --group) arch-rootfs-${IMGTAG}.tar.xz

# commit the changes
git add Dockerfile arch-rootfs-${IMGTAG}.tar.xz && git commit -m "Update Dockerfile and rootfs (${IMGTAG})" || true
git tag -m "Based on kernel $KERNELTAG and packages of $DATETAG" $IMGTAG

. ./build_params.sh

docker build \
  --build-arg BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg BUILD_DATE=$DATETAG \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  --build-arg KERNEL_VERSION=$KERNELTAG \
  --tag=$docker_image --file=$docker_file $docker_context
