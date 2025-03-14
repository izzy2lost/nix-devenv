#!/bin/bash
RESTART_INSTRUCTIONS="Dropping to shell. To rebuild, exit the script and restart the process."

mkdir -p artifact  # Create an artifact directory

cat <<EOF
____ ____ ____ ___ 
|    |  | |  | |__]
|___ |__| |__| |   
___  _  _ _ _    ___  ____ ____
|__] |  | | |    |  \ |___ |__/
|__] |__| | |___ |__/ |___ |  \\
EOF

if read -r -s -n 1 -t 5 -p "Press any key within 5 seconds to cancel build" key; then
    echo && echo $RESTART_INSTRUCTIONS
    exit 0
fi

echo 'Autodetecting baserom.us.z64. This can take a long time.'

if [ -f ~/baserom.us.z64 ]; then
    BASEROM_PATH=~/baserom.us.z64
else
    BASEROM_PATH=$(find / -type f -exec md5sum {} + 2>/dev/null | grep '^20b854b239203baf6c961b850a4a51a2' | head -n1 | cut -d' ' -f3-)
fi

BLOCKS_FREE=$(df --output=avail / | tail -n1)

if (( 2097152 > BLOCKS_FREE )); then
    cat <<EOF
____ _  _ _    _   
|___ |  | |    |   
|    |__| |___ |___
EOF
    echo 'Your device storage needs at least 2 GB free space to continue!'
    echo $RESTART_INSTRUCTIONS
    exit 1
fi

if [ -z "${BASEROM_PATH}" ]; then
    cat <<EOF
_  _ ____    ____ ____ _  _
|\ | |  |    |__/ |  | |\/|
| \| |__|    |  \ |__| |  |
EOF
    echo 'Go to https://github.com/sanni/cartreader to learn how to get baserom.us.z64'
    echo $RESTART_INSTRUCTIONS
    exit 2
else
    cp "${BASEROM_PATH}" ~/baserom.us.z64
fi

apt-mark hold bash
yes | apt update && apt upgrade -y
yes | apt install git wget make python getconf zip clang binutils libglvnd-dev aapt apksigner which -y

cd
if [ -d "sm64coopdx" ]; then
    cp "${BASEROM_PATH}" sm64coopdx/baserom.us.z64
    cd sm64coopdx
    git reset --hard HEAD
    git pull origin android
    git submodule update --init --recursive
    make distclean
else
    git clone --recursive https://github.com/ManIsCat2/sm64coopdx.git
    cp "${BASEROM_PATH}" sm64coopdx/baserom.us.z64
    cd sm64coopdx
fi

make 2>&1 | tee build.log

if ! [ -f build/us_pc/sm64coopdx.apk ]; then
    cat <<EOF
____ ____ _ _    _  _ ____ ____
|___ |__| | |    |  | |__/ |___
|    |  | | |___ |__| |  \ |___
EOF
    echo $RESTART_INSTRUCTIONS
    exit 3
fi

# Move APK to artifact directory
cp build/us_pc/sm64coopdx.apk artifact/

cat <<EOF
___  ____ _  _ ____
|  \ |  | |\ | |___
|__/ |__| | \| |___
EOF
echo "APK built successfully: artifact/sm64coopdx.apk"
echo "GitHub Actions will upload it as an artifact."

echo $RESTART_INSTRUCTIONS
