#!/bin/bash

for file in *.png; do

    #magick $file -blur 0x8   0.png
    #magick $file -blur 0x16  1.png
    #magick $file -blur 0x32  2.png
    #magick $file -blur 0x64  3.png
    #magick $file -blur 0x128 4.png
    #magick $file -blur 0x256 -alpha opaque 5.png

    #magick 5.png 4.png 3.png 2.png 1.png 0.png $file -layers flatten out.png

    gmic -input $file -solidify 75 -output out.png

    magick $file -alpha extract alpha.png

    magick out.png -alpha on \( +clone -channel a -fx 0 \) +swap alpha.png -composite $file

done
