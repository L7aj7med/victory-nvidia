# VIctory on an RTX 5080

A private build of [VIctory](https://github.com/Marvisak/VIctory), a compatibility layer
that runs an Xbox Series title on Windows from files the user supplies. This one
is tuned for **NVIDIA (RTX 50 series)**, built from the cool_fox fork with fixes
merged from many other forks, plus fixes of our own.

**This repository contains no game files, code or assets.** You need your own copy
of the game. It is not affiliated with or endorsed by the game's developer or
publisher.

## Where it stands (2026-11-26)

Tested on one machine only: Windows 11 Pro, Intel i9-12900KF, 64 GB DDR5-5600,
**GeForce RTX 5080 (16 GB)**, driver 616.64, a 2560x1440 240 Hz monitor, game on an NVMe drive.

| Setup | Real fps | Notes |
|---|---|---|
| Series S, fast (no ray tracing) | 23-28 | Stable. With NVIDIA Smooth Motion about 50 shown. Renders 1280x720, outputs 1920x1080. |
| Series S, ray tracing | ~22 outdoors, lower indoors | Was 6-8 before the defrag shader was left out. |
| Series X, ray tracing, 1440p output | ~12 (median 12.5) | 4K output: 7.8. Video memory nearly full. |
| Series X, fast, 1440p output | 15-20 | Video memory full (15.9 of 16 GB): stutters, textures arrive late. |

Measured with scripted 8-minute runs; the title's idle camera changes the scene, so
the figures are medians of the later minutes.

### What is known to be wrong

- **Ray tracing:** blocky dark tiles in some places; indoors the screen-probe trace
  (`CS_ScreenProbes_TraceRays`) costs up to 44 ms a frame.
- **Series X needs more than 16 GB of video memory** with this layer (its own
  copies add about 2.6 GB). Series X with ray tracing plus Smooth Motion runs out
  and stalls; Series X fast mode stutters.
- **Series X: noise on skin** (rainbow or green hands and arms) while the texture
  queue is long (27,000 slots waiting).
- **The GPU is busy but mostly empty:** about 95% load at only ~100 W of the
  card's 360 W. The work reaches the card in small, serialized pieces; this is
  where most of the missing speed is.
- **Series S cannot go sharper:** the title refuses a 2560x1440 output and a
  FidelityFX render scale of 1.0 on Series S (it stops on its own check at start).
- Fast mode lights shadowed areas with a stand-in; some rooms are darker than
  with ray tracing.
- Turning the camera smears colour at low frame rates (temporal reprojection).
- A cold shader cache shows garbled faces and stutters for the first minutes.

## How to run it

Build (Rust, Windows x64):

```powershell
cargo build --locked --release -p victory
```

Then use the launchers in [`launcher/`](launcher). Edit the paths at the top of
`Play-GTA.ps1` (the build, your game folder and the log folder) first.

| Launcher | Setup |
|---|---|
| `Play GTA (fast).cmd` | Series S, no ray tracing: the smoothest |
| `Play GTA (ray tracing).cmd` | Series S, ray tracing |
| `Play GTA (fast, Series X).cmd` | Series X, no ray tracing, 2560x1440 |
| `Play GTA (fast, Series X, sharp).cmd` | Same, rendered at native 1440p (slower) |
| `Play GTA (ray tracing, Series X).cmd` | Series X, ray tracing, 2560x1440 |

`Play-GTA.ps1 -Mode fast|rt -Console series-s|series-x [-Scale 0.5-1.0] [-Output WxH]`.

Saves and the shader cache live in `%LOCALAPPDATA%\cool_fox`. Close the game with
its window's close button: that saves and exits cleanly.

**NVIDIA App:** Smooth Motion (driver frame generation) works on
`victory.exe` and roughly doubles the frames shown. Use it with Series S, or
Series X fast mode; not with Series X ray tracing (out of video memory). Image
Scaling's sharpening (30-50%) helps the soft Series S picture. DLSS cannot be
used: the title has no DLSS, and no override tool can add it.

## Switches this build adds or relies on

| Switch | What it does |
|---|---|
| `VICTORY_SKIP_PIPELINES=02384a60fda6f2d0` | Leaves out `CS_DefragHeap_ComputeRelocations`, which cost ~54 ms of GPU time a frame on NVIDIA. Works in release builds. |
| `VICTORY_PORT_CBV=1` | In-place constant buffers: -13% CPU preparation, +4.5% fps. |
| `VICTORY_VSYNC=0-4` | Present with a sync interval; 1 stops tearing. |
| `VICTORY_RECHECK_FRAMES=2,4,...,256`, `VICTORY_RECHECK_FOREVER=1` | Our texture fix: look at uploaded textures sooner and never stop, so stale textures are corrected fast (mid-range staleness 40 to 8 frames, ~2 fps). |
| `VICTORY_AMBIENT_TINT=0-1` | Fast mode's stand-in light keeps the probes' brightness with our estimate's colour (no purple foliage at dusk). |
| `VICTORY_AMBIENT=1.2` (Series X fast: 1.6) | Brightness of the stand-in light. |
| `VICTORY_OUTPUT=WxH` | The title's output size (Series X: 2560x1440 is 60% faster than 4K). |
| `VICTORY_RENDER_SCALE=0.5-1.0` | Series X: the title's own upscaler's render scale (2/3 by default). |
| `VICTORY_BVH_BUILDER=1`, `VICTORY_BVH_SIZES_WAIT=1` | Ray tracing. |

Tried and left off: the 60 fps unlock (crashes), pinning to P-cores (slower),
refusing the FidelityFX DLL (the title divides by zero), `VICTORY_FILL_TITLE`
and `VICTORY_PLACED_ORDER` (no measurable change in a same-run A/B).

## Where this build comes from

[Marvisak/VIctory](https://github.com/Marvisak/VIctory), then the cool_fox fork
(codec_d) and VItoriaBr, with commits merged from forks by Yoshi-233,
superboynick, oceansde012, mattkajorinc, PookiePepelsss, TaynanGT / Vice-Tay,
dima424658, Ranxanat0r, DoubleGhosty, larpingtung and Davidjc13; ports of work by
dng-nguyn, flipflapov and wardevsa; and part 1 of ScarlettPort pull request #25
(ZigZagBoi1). The full list with commit ids is in the history (`a66326c1` and
later). The previous README, from the RX 7900 XTX fork, is in the history too.
