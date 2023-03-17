#!/bin/bash

function check_package() {
    REQUIRED_PKG="$1"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG 2> /dev/null | grep "install ok installed")
    [ -n "$PKG_OK" ] && return $?
}

# requires qrencode and ffmpeg
check_package "zbar-tools" || { echo "[!] zbar-tools package is missing. Please install it: sudo apt-get install zbar-tools"; exit 1; }
check_package "ffmpeg" || { echo "[!] ffmpeg package is missing. Please install it: sudo apt-get install ffmpeg"; exit 1; }

# get file from input
file="$1"
output="$2"

# check if 2nd argument is provided
if [ -z "$output" ]; then
    output="original.dat"
fi

# check if the file exists
if [ ! -f "$file" ]; then
    echo "Input file not found"
    exit 1
fi

# split gif
echo "Splitting GIF into QR PNGs..."
ffmpeg -i "$file" -fps_mode passthrough frame%d.png

# calculate number of qrcodes
nqrcodes=$(ls -1 frame* | wc -l)

# decode qrcodes
echo "Decoding qrcodes..."
for i in $(seq 1 $nqrcodes); do
    zbarimg -q frame$i.png | sed 's/QR-Code://' | perl -pe 'chomp if eof' >> $output
done

# clean up
echo "Cleaning up..."
rm -f frame*

echo "Done!"
