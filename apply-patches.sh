#!/bin/bash

set -e

patches="$(readlink -f -- $1)"

for project in $(cd $patches/patches; echo *);do
    p="$(tr _ / <<<$project)"
    [ "$p" == build ] && p=build/make
    repo sync -l --force-sync $p || continue
    pushd $p
    git clean -fdx; git reset --hard
    for patch in $patches/patches/$project/*.patch;do
        if git apply --check $patch;then
            echo -e "\033[01;32m"
            git am $patch
            echo -e "\033[0m"
        elif patch -f -p1 --dry-run < $patch > /dev/null;then
            #This will fail
            echo -e "\033[32m"
            git am $patch || true
            patch -f -p1 < $patch
            git add -u
            git am --continue
            echo -e "\033[0m"
        else
            echo -e "\033[01;31m\n Failed applying $patch ...\033[0m"
        fi
    done
    popd
done
