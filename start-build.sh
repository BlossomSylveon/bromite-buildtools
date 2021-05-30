#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

#if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
#    GITHUB_SHA=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.head.sha)
#fi

sudo apt-get install -y libxkbcommon-dev

echo -e ${RED} -------- set envs ${NC}
PATH=$PWD/chromium/src/third_party/llvm-build/Release+Asserts/bin:$PWD/depot_tools/:/usr/local/go/bin:$PATH

cd chromium/src

echo -e ${RED} -------- gn gen ${NC}
gn gen --args="$(cat ../../bromite/build/GN_ARGS) target_cpu=\"x86\" use_goma=true goma_dir=\"../../goma\" " out/x86

echo -e ${RED} -------- checking prebuild ${NC}
rm out.$GITHUB_SHA.tar.gz
lftp $FTP_HOST -u $FTP_USER,$FTP_PWD -e "set ftp:ssl-force true; set ssl:verify-certificate false; cd /bromite; get out.x86.$GITHUB_SHA.tar.gz; quit" && OK=1 || OK=0

if [[ OK -eq 1 ]]; then
    echo -e ${RED} -------- unpacking prebuild ${NC}

    tar xf out.x86.$GITHUB_SHA.tar.gz

    # TODO add mtool restore
fi

echo -e ${RED} -------- start build ${NC}
autoninja -j 40 -C out/x86 chrome_public_apk

# TODO add mtool backup

echo -e ${RED} -------- tar out ${NC}
tar -czf out.x86.$GITHUB_SHA.tar.gz ./out

echo -e ${RED} -------- uploading to storage ${NC}
lftp $FTP_HOST -u $FTP_USER,$FTP_PWD -e "set ftp:ssl-force true; set ssl:verify-certificate false; cd /bromite; put out.x86.$GITHUB_SHA.tar.gz; quit"
