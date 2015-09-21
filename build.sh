#!/bin/bash

set -e

DATETAG=$(date +"%Y%m%d")
KERNELTAG=$(pacman -Q linux | cut -d' ' -f2)
IMGTAG=${DATETAG}_${KERNELTAG}

# remove any existing root filesystem from the repo history
git tag -d $(git tag -l) || true
git filter-branch -f --tag-name-filter cat --commit-filter 'git_commit_non_empty_tree "$@"' --tree-filter 'rm -f arch-rootfs*' master
git reflog expire --expire=now --all &&  git repack -ad && git gc --aggressive --prune=now

# build an updated root filesystem
sudo ./mkimage-arch.sh ${IMGTAG}

# update the Dockerfile with the latest build "number"
sed "s/TAG/${IMGTAG}/" Dockerfile.tpl > Dockerfile

# commit the changes
git add Dockerfile && git commit -m "Update Dockerfile (${IMGTAG})"
git add arch-rootfs-${IMGTAG}.tar.xz && git commit -m "Update rootfs (${IMGTAG})"
git tag -m "Based on kernel $KERNELTAG and packages of $DATETAG" $IMGTAG
