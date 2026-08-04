.PHONY: all multitap-detect port2-control multitap-probe test clean

all:
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

test: all multitap-detect
	sh tests/mesen/run.sh

clean:
	rm -rf build
