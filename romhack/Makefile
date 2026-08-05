.PHONY: all context-block-move-probe context-swap-probe multitap-detect port2-control multitap-probe render-layer-probe static-four-wells test clean

all:
	./build.sh

context-block-move-probe:
	PATCH_FILE="$(CURDIR)/experiments/context-block-move-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/context-block-move-probe.sfc" \
	./build.sh

context-swap-probe:
	PATCH_FILE="$(CURDIR)/experiments/context-swap-probe.asm" \
	OUTPUT_ROM="$(CURDIR)/build/context-swap-probe.sfc" \
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

test: all context-block-move-probe context-swap-probe multitap-detect static-four-wells
	sh tests/mesen/run.sh

clean:
	rm -rf build
