#!/bin/sh

make

echo "testing consistent branches"
for i in {0..10}
do
  time -p bp-same
done

echo "testing random branches"
for i in {0..10}
do
  time -p bp-random
done
