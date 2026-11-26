# One-click launcher for the GTA VI Xbox dump on the local cool_fox build.
#   Play-GTA.ps1 -Mode rt     ray tracing on (best picture, ~7-12 fps)
#   Play-GTA.ps1 -Mode fast   ray tracing off (~27-29 fps)
# Series S profile, release build, settings as tuned on 2026-11-26.
param(
    [ValidateSet("rt", "fast")][string]$Mode = "rt",
    [ValidateSet("series-s", "series-x")][string]$Console = "series-s",
    # Series X only: the share of the output size the game renders at before its
    # own upscaler (2/3 if not given; 1.0 = native, sharpest, slowest).
    [ValidateRange(0.5, 1.0)][double]$Scale = 0,
    # The game's output size (Series X defaults to 2560x1440 below, Series S to its own 1920x1080).
    [ValidateSet("", "1920x1080", "2560x1440", "3840x2160")][string]$Output = ""
)
$exe  = "X:\ztrx build\cool_fox\target\release\victory.exe"
$game = "X:\GTA.Xbox.v1.0.2.1\game_scarlett_master.exe"
$logs = "X:\ztrx build"

if (Get-Process victory -ErrorAction SilentlyContinue) {
    Write-Host "The game is already running. Close its window first (that saves and exits cleanly)."
    Read-Host "Press Enter to close this window" | Out-Null
    exit 1
}

# Start from a clean set of switches, then apply ours.
Get-ChildItem Env: | Where-Object { $_.Name -like "VICTORY_*" } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
$set = [ordered]@{
    VICTORY_CACHE_DIR          = "$env:LOCALAPPDATA\cool_fox\cache"
    VICTORY_DATA_DIR           = "$env:LOCALAPPDATA\cool_fox\data"
    VICTORY_WIDE_REFRESH       = "1"
    VICTORY_ASYNC_SUBMIT       = "1"
    VICTORY_TEXTURE_NO_WAIT    = "1"
    VICTORY_AMBIENT            = "1.2"
    VICTORY_AMBIENT_SHADE      = "0"
    VICTORY_THREAD_TICKET      = "1"
    VICTORY_WAVE_LDS_LOOSE     = "0"
    VICTORY_SHADER_OPT         = "0"
    VICTORY_AMBIENT_AIR        = "1.5"
    VICTORY_RELAY              = "2"
    VICTORY_WIDE_BACK          = "1"
    VICTORY_CARD_REHASH_RUNS   = "1"
    VICTORY_JOIN_COPIES        = "1"
    VICTORY_INDIRECT_WINDOW    = "1"
    VICTORY_RELAY_COPY         = "1"
    VICTORY_CARD_STEPS         = "2"
    VICTORY_INDIRECT_BATCH     = "2"
    VICTORY_MAP_THREADS        = "1"
    VICTORY_CARD_AWAKE         = "1"
    VICTORY_SHOW_AFTER         = "1"
    VICTORY_THIN               = "1"
    VICTORY_JOIN_PARTS         = "8"
    VICTORY_UPLOAD_AHEAD       = "1"
    VICTORY_LEVELS_ON_DEMAND   = "1"
    VICTORY_CARD_BUFFERS_MIN_KB = "64"
    VICTORY_LOG                = "warn,victory_gpu::host=info"
    # CS_DefragHeap_ComputeRelocations: translates since Davidjc13 54cb6ace but costs
    # ~54 ms of GPU time a frame on NVIDIA (timing run 2026-11-26); the game ran fine
    # when it was refused, so it stays left out.
    VICTORY_SKIP_PIPELINES     = "02384a60fda6f2d0"
    # Wait for the monitor's refresh before showing a frame: no tearing in full screen.
    VICTORY_VSYNC              = "1"
    # In-place constant buffers (DoubleGhosty fad4e536 + Vice-Tay 0d344fd5):
    # -13% CPU preparation, +4.5% fps in the 2026-11-26 benchmark.
    VICTORY_PORT_CBV           = "1"
    # Our texture fix: look at uploaded textures sooner and never stop looking,
    # so wrong or stale textures are corrected fast (A/B 2026-11-26: 31 more
    # changes caught, mid-range staleness 40 -> 8 frames, about 2 fps).
    VICTORY_RECHECK_FRAMES     = "2,4,8,16,32,64,128,256"
    VICTORY_RECHECK_FOREVER    = "1"
    # Fast mode's stand-in light: keep the probes' brightness but our estimate's
    # colour, so stale blue-purple blocks on foliage at dusk turn into proper light.
    VICTORY_AMBIENT_TINT       = "1"
}
if ($Mode -eq "rt") {
    $set.VICTORY_BVH_BUILDER = "1"
    $set.VICTORY_BVH_SIZES_WAIT = "1"
}
if ($Console -eq "series-x") {
    # Series X outputs 4K by default; 2560x1440 (the monitor's size) ran 12.5 fps
    # median against 7.8 at 4K and 7.9 at 1920x1080 (ray tracing, 2026-11-26).
    $set.VICTORY_OUTPUT = "2560x1440"
    if ($Scale -gt 0) { $set.VICTORY_RENDER_SCALE = $Scale.ToString([Globalization.CultureInfo]::InvariantCulture) }
    # Fast mode's stand-in light was tuned on Series S; Series X came out darker.
    if ($Mode -eq "fast") { $set.VICTORY_AMBIENT = "1.6" }
}
if ($Output) { $set.VICTORY_OUTPUT = $Output }
# (Series S refuses both a 2560x1440 output and VICTORY_FFX_SCALE=1.0: the title
# stops on its own check at start, 0x80000003, tried 2026-11-26.)
foreach ($k in $set.Keys) { Set-Item "Env:$k" $set[$k] }

Start-Process -FilePath $exe -ArgumentList @("run", "--execute", "--console", $Console, "`"$game`"") `
    -RedirectStandardOutput "$logs\coolfox.log" -RedirectStandardError "$logs\coolfox.err.log" | Out-Null
Write-Host "GTA VI started ($Mode, $Console). Logs: $logs\coolfox.err.log"
