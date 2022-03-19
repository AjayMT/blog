#!/bin/sh

make

echo "testing consistent branches"
for i in {0..10}
do
  time ./bp-same
  echo ""
done

echo "testing random branches"
for i in {0..10}
do
  time ./bp-random
  echo ""
done
