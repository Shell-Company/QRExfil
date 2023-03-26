#!/bin/bash

function check_package() {
    REQUIRED_PKG="$1"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG 2> /dev/null | grep "install ok installed")
    [ -n "$PKG_OK" ] && return $?
}

# requires qrencode and ffmpeg
check_package "qrencode" || { echo "[!] qrencode package is missing. Please install it: sudo apt-get install qrencode"; exit 1; }
check_package "ffmpeg" || { echo "[!] ffmpeg package is missing. Please install it: sudo apt-get install ffmpeg"; exit 1; }

# get file from input
file="$1"
output="$2"

# check if 2nd argument is provided
if [ -z "$output" ]; then
    output="output.gif"
fi

# check if the file exists
if [ ! -f "$file" ]; then
    echo "Input file not found"
    exit 1
fi

# get size of file in bytes
# filesize=$(stat -f "%z" "$file" || stat -c%s "$file")
if [ "$(uname)" == "Darwin" ]; then
    filesize=$(stat -f "%z" "$file")
else
    filesize=$(stat -c%s "$file")
fi

# calculate size of each chunk
chunksize=64

# determine number of chunks
nchunks=$((filesize/chunksize))

# create chunks
echo "Creating chunks..."
for i in $(seq 0 $nchunks); do
    dd if="$file" of=chunk_"$i" bs="$chunksize" skip="$i" count=1
    echo "Created chunk $i"
done

# generate qrcode images
echo "Generating qrcodes..."
for i in $(seq 0 $nchunks); do
    qrencode -t png -o frame_"$i".png < chunk_"$i" -s 8 -8
    echo "Generated qrcode $i"
done

# combine qrcode images into gif
echo "Creating gif..."
if [ "$(uname)" == "Darwin" ]; then
    ffmpeg -y -r 10 -i frame_%d.png $output 
else
    ffmpeg  -i frame_%d.png $output  -y -r 10 
fi

# clean up
echo "Cleaning up..."
rm -f chunk_*
rm -f frame_*

echo "Done!"
