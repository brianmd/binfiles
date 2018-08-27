#!/bin/bash
for drive in {0..3}; do for partition in {1..4}; do parted --script /dev/nvme${drive}n1 rm ${partition}; done; done

for drive in {0..3}; do
  parted --script /dev/nvme${drive}n1 \
    mklabel gpt \
    mkpart primary 0% 18% \
    mkpart primary 18% 36% \
    mkpart primary 36% 54% \
    mkpart primary 54% 72%
done
