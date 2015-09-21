#!/bin/bash

set -e

IMGTAG=$(date +"%Y%m%d")_$(pacman -Q linux | cut -d' ' -f2)

# remove any existing root filesystem from the repo history
git filter-branch -f --tag-name-filter cat --commit-filter 'git_commit_non_empty_tree "$@"' --tree-filter 'rm -f arch-rootfs*' master
git reflog expire --expire=now --all &&  git repack -ad && git gc --aggressive --prune=now

# build an updated root filesystem
sudo ./mkimage-arch.sh ${IMGTAG}

# update the Dockerfile with the latest build "number"
sed "s/TAG/${IMGTAG}/" Dockerfile.tpl > Dockerfile

# commit the changes
git add Dockerfile && git commit -m "Update Dockerfile (${IMGTAG})"
git add arch-rootfs-${IMGTAG}.tar.xz && git commit -m "Update rootfs (${IMGTAG})"
