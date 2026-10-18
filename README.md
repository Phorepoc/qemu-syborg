# qemu-syborg

The QEMU that ran the 2010 Symbian open-source release: the Symbian Foundation's fork of QEMU 0.9.1
(`qemu-symbian-svp` 0.9.1-12) with the **Syborg** virtual board. It is packaged as a container image, so it still
builds and runs today: `ghcr.io/phorepoc/qemu-syborg`.

The fork needs a 2011-era userland (gcc 4.4, Python 2.6 for the Syborg device plug-ins, SDL 1.2, libpng 1.2), so the
image is a Debian squeeze build. The source is the Phorepoc fork of
[`oss.FCL.sf.adapt.Qemu`](https://github.com/Phorepoc/oss.FCL.sf.adapt.Qemu) at the commit in
[`source.lock`](source.lock), plus three small patches:

| Patch | Why |
|---|---|
| `01-syborg_nvmemorydevice` | The flash-disk plug-in called its C library through `ctypes` without declaring argument types. On a 64-bit host every pointer was cut to 32 bits, and QEMU crashed on the first disk access. QEMU 0.9.1 also parses the shared-memory region's base and size with the wrong format on 64-bit hosts, so every transfer went to guest address 0. |
| `02-syborg_pointer` | The monitor's `mouse_button` reports clicks at (0,0), which is useless for an absolute pointer. A click now keeps the last position, so `mouse_move X Y` + `mouse_button 1` taps at X,Y. |
| `03-fb_dump_hook` | Writes the guest framebuffer to a PPM file (`$SYBORG_FB_DUMP`) every frame, so a headless run can be checked as a picture. |

## Use

```sh
docker run --rm -i -v "$PWD:/work" ghcr.io/phorepoc/qemu-syborg run-syborg /work/my.rom 90
```

`run-syborg <rom> [seconds]` boots headless:
- serial port 0 goes to `/work/serial.log`;
- the screen goes to `/work/fb.ppm`;
- stdin is the QEMU monitor, so piping `sendkey d` and so on types into the guest.

Set `C_DRIVE=/work/c.img` to provide the C: drive as a FAT image (it is copied, not modified), and `DTB=...` to use
another board description.

## Licence

GPL-2.0 ([LICENSE](LICENSE)), as QEMU itself. The source and our patches are all in this repository and its pinned
source fork, alongside the published image.
