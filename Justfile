set dotenv-load

goldie_path := env_var('GOLDIE_REPO')
phippy_path := env_var('PHIPPY_REPO')
ferris_path := env_var('FERRIS_REPO')

# Build everything
build: build-goldie build-phippy build-ferris

build-goldie:
    cd {{goldie_path}} && bun install && bun run build
    mkdir -p {{ferris_path}}/static/goldie
    cp -r {{goldie_path}}/dist/ {{ferris_path}}/static/goldie/

build-phippy:
    cd {{phippy_path}} && bun install && bun run build
    mkdir -p {{ferris_path}}/static/phippy
    cp -r {{phippy_path}}/dist/ {{ferris_path}}/static/phippy/

build-ferris:
    cd {{ferris_path}} && cargo build --release
    mkdir -p release
    cp {{ferris_path}}/target/release/ferris release/