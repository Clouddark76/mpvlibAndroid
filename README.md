# mpvlib Android

**MpvRx / mpvlibAndroid** — An Android video player library built on mpv with full **yt-dlp**, **Python 3.12**, and **libcurl** support baked in.

## What is This?

This library brings the full power of mpv to Android — play any video, stream YouTube links, run Python scripts, download with curl, generate thumbnails, and more. All through a simple Kotlin API.

## Features

### 🎥 Core Video Playback
- Full mpv engine on Android — play virtually any media file
- 200+ formats supported (mp4, mkv, avi, mov, webm, flac, mp3, gif, etc.)
- 15+ network protocols: http, https, rtmp, rtmps, rtp, rtsp, mms, tcp, udp, srt, srtp, and more
- Android Surface rendering with hardware acceleration

### 🎬 Next-Gen Codecs (FFmpeg n8.1.1)
- **VVC (H.266)** — Versatile Video Coding via Fraunhofer vvdec, ~30% better than HEVC
- **xHE-AAC / USAC** — Extended HE-AAC, used by streaming sites (native FFmpeg decoder)
- **Samsung APV** — Advanced Professional Video lossless codec for Galaxy camera workflows
- **MPEG-H 3D Audio** — Immersive object-based 3D audio (Fraunhofer decoder), ATSC 3.0
- **IAMF** — Immersive Audio Model and Formats (Alliance for Open Media)
- **LCEVC** — Low Complexity Enhancement Video Coding (MPEG-5 Part 2)
- **AV1** — Alliance for Open Media via dav1d (NEON optimized)

### 🖥️ Vulkan Rendering (gpu-next)
- Advanced Vulkan 1.3 GPU rendering pipeline via `libplacebo` + `shaderc`
- MPV native hardware-accelerated video scaling and color management
- Supported GPUs: Adreno 600+ (Snapdragon 845+), Mali-G77+ (Dimensity/Exynos), Xclipse (Exynos 2200+)

### ⚡ ARM v9a Optimized
- **Dual-tier ARM64 builds**: base v8a + v9a optimized
- **Runtime ABI auto-detection**: SVE2 feature check at app launch
- **ARM v8a**: NEON optimized, 8-10% performance boost over default
- **ARM v9a**: SVE2 + I8MM optimized, 15-18% performance boost
- Compatible v9a SoCs: Snapdragon 8 Gen 2/3, Dimensity 9200/9300, Exynos 2400+, Cortex-X3+
- Built with NDK r29 (Clang 20.x) with LTO and aggressive optimization flags

### ▶️ yt-dlp Support
- YouTube, Twitch, and 1000+ sites supported out of the box
- yt-dlp v2026.03.17 bundled and ready
- Just pass a YouTube URL — yt-dlp handles the rest

### 🐍 Python 3.12 Runtime
- Full Python 3.12.3 runtime compiled for Android
- Bundled per-architecture (arm64, x86, x86_64)
- Includes stdlib with common modules (ssl, bz2, ctypes, lzma, hashlib, uuid)
- Used by yt-dlp internally, also available for your own scripts

### 🌐 libcurl (HTTP Networking)
- Built with MbedTLS for secure connections
- Optimized for minimal size — only the protocols actually needed
- Powers network streaming and downloads

### 🖼️ Thumbnail Generation
- Two engines: mpv-based and direct FFmpeg
- Hardware-accelerated with MediaCodec
- Sync, async, and batch modes
- ~50-100ms per thumbnail

### 📜 Scripting
- **Lua** 5.2.4 — mpv scripts work as-is
- **JavaScript** via MuJS 1.3.9
- **Python** 3.12 — for custom logic and automation

### 🔒 Security
- SSL/TLS via both MbedTLS and OpenSSL
- CA certificate bundle included
- Secure streaming by default

### 🎨 Video Output
- Vulkan 1.3 rendering via libplacebo + shaderc
- Vulkan compute video filters
- GPU shader cache support
- Subtitle rendering with libass + HarfBuzz + FriBidi
- AV1 decoding via dav1d (NEON/SVE2 optimized)

### ⚡ Modern Android API
- Kotlin-friendly with StateFlow / Flow support
- Observe any mpv property reactively
- Typed property delegates (Int, Long, Float, Double, Boolean, String, Node)

## Requirements

- Android 7.0+ (API 24+)
- Android Studio
- JDK 17+

## Quick Start

### Installation

1. Download the AAR from [releases](https://github.com/Riteshp2001/mpvlibAndroid/releases)
2. Place it in `app/libs/`
3. Add to your `build.gradle`:

```gradle
dependencies {
    implementation(files("libs/mpvlib.aar"))
}
```

### Basic Usage

```kotlin
import is.xyz.mpv.MPVLib
import is.xyz.mpv.AbiDetector

// Initialize with v9a auto-detection (recommended)
MPVLib.loadLibraries(context)

MPVLib.create(context)
MPVLib.init()

// Play anything — local file, YouTube URL, stream, VVC, xHE-AAC
MPVLib.command("loadfile", "https://youtube.com/watch?v=...")
MPVLib.command("loadfile", "/sdcard/video.mp4")
MPVLib.command("loadfile", "/sdcard/video.vvc")  // VVC (H.266)

// Controls
MPVLib.setPropertyBoolean("pause", true)
MPVLib.setPropertyBoolean("pause", false)

// Check detected ABI tier
val abiTier = AbiDetector.detectOptimalAbi()
println("Running on: ${abiTier.displayName}") // e.g., "ARM64 v9a (SVE2+NEON)"

// Thumbnail
FastThumbnails.initialize(context)
FastThumbnails.generate("video.mp4", positionSec = 30.0, width = 320)
```

## Building from Source

### Prerequisites

```bash
sudo apt install openjdk-17-jdk ninja-build cmake autoconf automake \
    libtool-bin pkg-config meson python3 python3-pip wget
pip install meson jinja2 jsonschema
```

### Commands

```bash
./buildscripts/download.sh    # Download SDK, NDK, and dependencies
./buildscripts/buildall.sh --arch arm64         # Build arm64-v8a (base)
./buildscripts/buildall.sh --arch arm64-v9a     # Build arm64-v9a (SVE2 optimized)
./buildscripts/buildall.sh                      # Build everything (all ABIs)
./buildscripts/docker-build.sh                  # Or build with Docker
```

Output: `app/build/outputs/aar/app-release.aar`

## Supported ABIs

| ABI | Arch | Optimization | Performance Boost |
|-----|------|-------------|-------------------|
| `arm64-v8a` | ARM64 | NEON + CRC + Crypto + LTO | 8-10% |
| `arm64-v9a` | ARM64 v9 | SVE2 + I8MM + NEON + LTO | 15-18% |
| `x86_64` | x86_64 | (optional) | — |
| `x86` | x86 | (optional) | — |

**v9a Runtime Detection**: The library automatically detects SVE2 capability at launch via `/proc/cpuinfo` and `getauxval(AT_HWCAP2)`. On v9a-capable devices (Snapdragon 8 Gen 2+, Dimensity 9200+, Exynos 2400+), optimized libraries are extracted from assets and loaded automatically.

## Key Classes

| Class | Purpose |
|-------|---------|
| `MPVLib` | Main API — init, play, pause, seek, properties, events |
| `AbiDetector` | Runtime ARM v9a detection and optimized library loading |
| `BaseMPVView` | Drop-in video surface for XML layouts |
| `FastThumbnails` | Generate thumbnails sync/async/batch |
| `Utils` | File helpers, metadata, storage, version info |
| `MPVNode` | Handle complex mpv data types |

## What's Inside

| Component | Version |
|-----------|---------|
| FFmpeg | n8.1.1 |
| VVC (H.266) | vvdec 2.3.0 |
| MPEG-H 3D Audio | mpeghdec 1.0.2 |
| IAMF | libiamf 1.0.0 |
| LCEVC | liblcevc 0.4.1 |
| yt-dlp | 2026.03.17 |
| Python | 3.12.3 |
| libcurl | 8.20.0 |
| Lua | 5.2.4 |
| MuJS (JavaScript) | 1.3.9 |
| MbedTLS | 3.6.5 |
| OpenSSL | 3.5.5 |
| HarfBuzz | 14.2.0 |
| FreeType | 2.14.3 |
| dav1d | latest |
| libplacebo | latest |
| Vulkan | 1.3.290 |
| Android NDK | r29 |
| Min API | 24 (Android 7.0) |

## License

**MIT License** — See [LICENSE](LICENSE).

## Credits

- [mpv](https://mpv.io/)
- Original authors: Ilya Zhuravlev and sfan5
