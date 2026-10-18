#!/bin/sh
# smoke.sh <image> -- QEMU starts the Syborg board: it loads the device tree, the Python device plug-ins (with our
# fixed flash-disk plug-in, which reports "created" once its disk is up). No guest ROM is needed for that.
set -eu
IMG=$1
out=$(echo quit | docker run --rm -i "$IMG" sh -c '
	head -c 4096 /dev/zero > /tmp/empty.rom
	cd /tmp && timeout 20 /opt/qemu-syborg/qemu-system-arm -L /opt/qemu-syborg -M /opt/qemu-syborg/syborg.dtb \
		-m 128 -kernel /tmp/empty.rom -serial null -monitor stdio 2>&1' || true)
echo "$out" | head -20
echo "$out" | grep -q "phorepoc-fixed plugin"
echo "$out" | grep -q "syborg_nvmemorydevice: created"
echo "smoke: OK"
