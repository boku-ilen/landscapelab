#!/bin/bash

for img in *.png; do
  convert -resize 100x "$img" "small-$img"
done
