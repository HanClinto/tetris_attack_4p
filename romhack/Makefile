.PHONY: all context-block-move-probe context-dispatch-probe context-swap-probe live-four-boards multitap-detect panel-assets port2-control multitap-probe render-layer-probe static-four-wells test clean

all:
	./build.sh

panel-assets:
	mkdir -p build
	ruby tools/compile_panel_tiles.rb assets/panels/panels.json build/panel-tiles.4bpp

context-block-move-probe:
	PATCH_FILE="$(CURDIR)/experiments/context-block-move-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/context-block-move-probe.sfc" \
	./build.sh

context-dispatch-probe:
	PATCH_FILE="$(CURDIR)/experiments/context-dispatch-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/context-dispatch-probe.sfc" \
	./build.sh

context-swap-probe:
	PATCH_FILE="$(CURDIR)/experiments/context-swap-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/context-swap-probe.sfc" \
	./build.sh

live-four-boards: panel-assets
	PATCH_FILE="$(CURDIR)/experiments/live-four-boards.asm" \
	OUTPUT_ROM="$(CURDIR)/build/live-four-boards.sfc" \
	./build.sh

multitap-detect:
	PATCH_FILE="$(CURDIR)/experiments/multitap-detect.asm" \
	OUTPUT_ROM="$(CURDIR)/build/multitap-detect.sfc" \
	./build.sh

port2-control:
	PATCH_FILE="$(CURDIR)/experiments/port2-auto-read.asm" \
	OUTPUT_ROM="$(CURDIR)/build/port2-auto-read.sfc" \
	./build.sh

multitap-probe:
	PATCH_FILE="$(CURDIR)/experiments/multitap-auto-read.asm" \
	OUTPUT_ROM="$(CURDIR)/build/multitap-auto-read.sfc" \
	./build.sh

render-layer-probe:
	PATCH_FILE="$(CURDIR)/experiments/render-layer-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/render-layer-probe.sfc" \
	./build.sh

static-four-wells:
	PATCH_FILE="$(CURDIR)/experiments/static-four-wells.asm" \
	OUTPUT_ROM="$(CURDIR)/build/static-four-wells.sfc" \
	./build.sh

test: all context-block-move-probe context-dispatch-probe context-swap-probe live-four-boards multitap-detect static-four-wells
	sh tests/mesen/run.sh

clean:
	rm -rf build
