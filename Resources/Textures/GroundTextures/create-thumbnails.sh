#!/bin/bash

for img in */*.jpg; do
  convert -resize 100x "$img" "small-$img"
done
