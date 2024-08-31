MAME = /Users/mike/mame0253-arm64/mame
mame_dir = $(dir $(MAME))
local_path = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
mame_args = -skip_gameinfo -window # -aviwrite pc6001.avi
asm_args = -w
asm = zasm

badam.bin: badam.asm 
	$(asm) $(asm_args) badam.asm -o badam.bin

all: badam.bin 

clean:
	rm -f pc6001.bin pc6001.lst meules.asm

run: badam.bin
	cd $(mame_dir) && $(MAME) adam $(mame_args) -cart1 $(local_path)badam.bin

debug: badam.bin
	cd $(mame_dir) && $(MAME) adam $(mame_args) -debug -cart1 $(local_path)badam.bin

openshots:
	open $(mame_dir)/snap/adam
