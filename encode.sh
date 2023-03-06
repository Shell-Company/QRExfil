#!/bin/bash
# requires qrencode and ffmpeg

# get file from input
file="$1"
output="$2"

# check if 2nd argument is provided
if [ -z "$output" ]; then
    output = "output.gif"
fi

# check if the file exists
if [ ! -f "$file" ]; then
    echo "File not found"
    exit 1
fi

# get size of file in bytes
filesize=$(stat -f "%z" "$file" || stat -c%s "$file")

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
    qrencode -t png -o frame_"$i".png < chunk_"$i" -s 8
    echo "Generated qrcode $i"
done

# combine qrcode images into gif
echo "Creating gif..."
ffmpeg  -y -r 2 -i frame_%d.png $output

# clean up
echo "Cleaning up..."
rm -f chunk_*
rm -f frame_*

echo "Done!"
