# mpvlib Android

**MpvRx / mpvlibAndroid** — An Android video player library built on mpv with full **yt-dlp**, **Python 3.13**, and **libcurl** support baked in.

## What is This?

This library brings the full power of mpv to Android — play any video, stream YouTube links, run Python scripts, download with curl, generate thumbnails, and more. All through a simple Kotlin API.

## Features

### 🎥 Core Video Playback
- Full mpv engine on Android — play virtually any media file
- 200+ formats supported (mp4, mkv, avi, mov, webm, flac, mp3, gif, etc.)
- 15+ network protocols: http, https, rtmp, rtmps, rtp, rtsp, mms, tcp, udp, and more
- Android Surface rendering with hardware acceleration

### ▶️ yt-dlp Support
- YouTube, Twitch, and 1000+ sites supported out of the box
- yt-dlp v2026.03.17 bundled and ready
- Just pass a YouTube URL — yt-dlp handles the rest

### 🐍 Python 3.13 Runtime
- Full Python 3.13.12 runtime compiled for Android
- Bundled per-architecture (arm64, arm32, x86, x86_64)
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
- **Python** 3.13 — for custom logic and automation

### 🔒 Security
- SSL/TLS via both MbedTLS and OpenSSL
- CA certificate bundle included
- Secure streaming by default

### 🎨 Video Output
- Vulkan rendering via libplacebo + shaderc
- GPU shader cache support
- Subtitle rendering with libass + HarfBuzz + FriBidi
- AV1 decoding via dav1d

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

MPVLib.create(context)
MPVLib.init()

// Play anything — local file, YouTube URL, stream
MPVLib.command("loadfile", "https://youtube.com/watch?v=...")
MPVLib.command("loadfile", "/sdcard/video.mp4")

// Controls
MPVLib.setPropertyBoolean("pause", true)
MPVLib.setPropertyBoolean("pause", false)

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
./buildscripts/buildall.sh    # Build everything (all 4 ABIs)
./buildscripts/docker-build.sh # Or build with Docker
```

Output: `app/build/outputs/aar/app-release.aar`

## Supported ABIs

- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM)
- `x86_64` (64-bit x86)
- `x86` (32-bit x86)

## Key Classes

| Class | Purpose |
|-------|---------|
| `MPVLib` | Main API — init, play, pause, seek, properties, events |
| `BaseMPVView` | Drop-in video surface for XML layouts |
| `FastThumbnails` | Generate thumbnails sync/async/batch |
| `Utils` | File helpers, metadata, storage, version info |
| `MPVNode` | Handle complex mpv data types |

## What's Inside

| Component | Version |
|-----------|---------|
| yt-dlp | 2026.03.17 |
| Python | 3.13.12 |
| libcurl | 8.20.0 |
| Lua | 5.2.4 |
| MuJS (JavaScript) | 1.3.9 |
| MbedTLS | 3.6.5 |
| OpenSSL | 3.5.5 |
| FFmpeg | n8.1 |
| HarfBuzz | 14.2.0 |
| FreeType | 2.14.3 |
| dav1d | latest |
| libplacebo | latest |
| Android NDK | r28c |
| Min API | 24 (Android 7.0) |

## License

**MIT License** — See [LICENSE](LICENSE).

## Credits

- [mpv](https://mpv.io/)
- Original authors: Ilya Zhuravlev and sfan5
