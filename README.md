# qemu-syborg

This is the emulator the Symbian Foundation used to run their 2010 open-source release: their fork of QEMU 0.9.1 with
the **Syborg** virtual board. It's 15 years old and won't build on a modern system, so we've packaged it as a container
image that still builds and runs today, `ghcr.io/phorepoc/qemu-syborg`.

Inside, it's built on Debian squeeze, because the fork needs a 2011-era toolchain: gcc 4.4, Python 2.6, SDL 1.2 and
libpng 1.2. The source comes from our fork of
[`oss.FCL.sf.adapt.Qemu`](https://github.com/Phorepoc/oss.FCL.sf.adapt.Qemu) at the commit in
[`source.lock`](source.lock), plus three small patches:

- **The flash disk works on 64-bit hosts.** The disk plug-in passed pointers to C without saying how big they were, so
  on a 64-bit machine they got cut in half and QEMU crashed on the first disk access.
- **Mouse clicks land where the pointer is.** The monitor's `mouse_button` used to click at (0,0), so tapping the
  screen from a script didn't work.
- **The screen can be saved to a file.** Every frame is written to `$SYBORG_FB_DUMP` as a PPM, so you can check a
  headless run by looking at a picture.

## Running it

```sh
docker run --rm -i -v "$PWD:/work" ghcr.io/phorepoc/qemu-syborg run-syborg /work/my.rom 90
```

That boots `my.rom` with no window for 90 seconds. The serial output goes to `serial.log`, the screen to `fb.ppm`, and
whatever you type on stdin goes to the QEMU monitor, so piping `sendkey d` into it types into the guest. Set
`C_DRIVE=/work/c.img` to give it a C: drive (we copy the image, so yours isn't changed), or `DTB=...` to use another
board description.

## Watching it live

This QEMU is older than working VNC, so there are two other ways to see the guest.

On any system, use `syborg-view.py`. Start the guest in live mode, which opens the monitor on port 4444 and refreshes
the screen dump five times a second:

```sh
docker run --rm -p 127.0.0.1:4444:4444 -v "$PWD:/work" -e LIVE=1 \
    ghcr.io/phorepoc/qemu-syborg run-syborg /work/my.rom 3600
python3 syborg-view.py fb.ppm 1
```

A window shows the screen, your keystrokes go to the guest, and mouse clicks and drags arrive as touches. All it needs
is Python 3 with Tk, which comes with the standard Windows and macOS installers. On Debian or Ubuntu, install
`python3-tk`.

On a Linux desktop you can also let QEMU open its own window, with keyboard and mouse:

```sh
docker run --rm -e DISPLAY -e SDL_VIDEODRIVER=x11 -v /tmp/.X11-unix:/tmp/.X11-unix -v "$PWD:/work" \
    ghcr.io/phorepoc/qemu-syborg run-syborg /work/my.rom 3600
```

If the container can't connect to your display, run `xhost +local:` first. WSLg on Windows should work the same way.

## License

GPL-2.0, like QEMU itself. The source and our patches are all here and in the pinned fork, next to the published image.
