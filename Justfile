set dotenv-load

goldie_path := env_var('GOLDIE_REPO')
phippy_path := env_var('PHIPPY_REPO')
ferris_path := env_var('FERRIS_REPO')

# OS-specific variables
os := if os() == "windows" { "windows" } else if os() == "macos" { "darwin" } else { "linux" }
ext := if os() == "windows" { ".exe" } else { "" }

# Build everything
build: build-goldie build-phippy setup-binaries build-ferris

build-goldie:
    cd {{goldie_path}} && bun install && bun run build
    mkdir -p {{ferris_path}}/static/goldie
    cp -r {{goldie_path}}/dist/ {{ferris_path}}/static/goldie/

build-phippy:
    cd {{phippy_path}} && bun install && bun run build
    mkdir -p {{ferris_path}}/static/phippy
    cp -r {{phippy_path}}/dist/ {{ferris_path}}/static/phippy/

# Download and setup yt-dlp and ffmpeg before building ferris
setup-binaries: download-ytdlp download-ffmpeg prepare-embedded

download-ytdlp:
    #!/usr/bin/env bash
    mkdir -p {{ferris_path}}/embedded
    echo "Downloading yt-dlp..."
    if [ "{{os}}" = "windows" ]; then
        curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o {{ferris_path}}/embedded/yt-dlp.exe
    else
        curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o {{ferris_path}}/embedded/yt-dlp
        chmod +x {{ferris_path}}/embedded/yt-dlp
    fi
    # Verify the download
    if [ "{{os}}" = "windows" ]; then
        ./{{ferris_path}}/embedded/yt-dlp.exe --version || exit 1
    else
        ./{{ferris_path}}/embedded/yt-dlp --version || exit 1
    fi

download-ffmpeg:
    #!/usr/bin/env bash
    mkdir -p {{ferris_path}}/embedded
    echo "Downloading ffmpeg..."
    if [ "{{os}}" = "windows" ]; then
        curl -L https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip -o ffmpeg.zip
        unzip -j ffmpeg.zip */bin/ffmpeg.exe -d {{ferris_path}}/embedded/
        rm ffmpeg.zip
    elif [ "{{os}}" = "darwin" ]; then
        brew install ffmpeg
        cp $(which ffmpeg) {{ferris_path}}/embedded/
    else
        curl -L https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ffmpeg.tar.xz
        tar xf ffmpeg.tar.xz
        cp ffmpeg-*-amd64-static/ffmpeg {{ferris_path}}/embedded/
        rm -rf ffmpeg-*-amd64-static ffmpeg.tar.xz
    fi

prepare-embedded:
    #!/usr/bin/env bash
    echo "Preparing embedded directory..."
    mkdir -p {{ferris_path}}/embedded
    if [ -f {{ferris_path}}/embedded/yt-dlp{{ext}} ] && [ -f {{ferris_path}}/embedded/ffmpeg{{ext}} ]; then
        echo "Binaries are ready"
    else
        echo "Error: Some binaries are missing"
        exit 1
    fi
    # Set proper permissions on Unix-like systems
    if [ "{{os}}" != "windows" ]; then
        chmod +x {{ferris_path}}/embedded/*
    fi

build-ferris:
    #!/usr/bin/env bash
    # Build from ferris directory but output to justfile directory
    CARGO_INCREMENTAL=1 RUST_LOG=info cargo build --release -j 1 --manifest-path {{ferris_path}}/Cargo.toml
    mkdir -p release
    cp {{ferris_path}}/target/release/ferris release/
    
# Run with debug logging
run-debug:
    RUST_LOG=trace ./release/ferris