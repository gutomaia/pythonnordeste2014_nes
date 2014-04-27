
ifeq "" "$(shell which python)"
default:
	@echo "Please install python"
	exit 1
else
default: pyne2014.png
endif

clean:
	@rm pyne2014.png


pyne2014.png:
	@convert pythonnordeste2014.png \
		-background yellow \
		-gravity center \
		-resize 200x200 \
		-extent 256x256 \
		-colors 4 \
		-depth 2 \
		+dither \
		pyne2014.png
	@touch $@




