FPC ?= fpc
FPCFLAGS = -Mobjfpc -Sh -O2 -g -gl -Cr -Co -Ci -Sa -vew -Fusrc -FUbuild -FEbuild
IMAGE ?= pascal-snake:local
TEST_IMAGE ?= pascal-snake-test:local
DOCKER ?= docker

.PHONY: help image test play smoke local-build local-test local-smoke local-play preview

help:
	@printf '%s\n' 'make test   - Pascal, PTY and SDL tests in Docker' 'make image  - build the terminal runtime image' 'make play   - play in an interactive terminal' 'make smoke  - test the packaged terminal image' 'make local-play - build and play the native desktop game' 'make local-build local-test local-smoke - use installed FPC, SDL + Python' 'make preview - regenerate the README screenshot (Docker + ImageMagick)'

image:
	$(DOCKER) build --target game -t $(IMAGE) .

test:
	$(DOCKER) build --target test -t $(TEST_IMAGE) .
	$(DOCKER) run --rm --network none $(TEST_IMAGE)

play: image
	$(DOCKER) run --rm -it --network none --read-only --cap-drop ALL --security-opt no-new-privileges $(IMAGE)

smoke:
	python3 tests/smoke_terminal.py --docker $(IMAGE)

build:
	mkdir -p build

build/SnakeGame: SnakeGame.pas src/snake_engine.pas src/snake_cli.pas src/snake_sdl.pas src/snake_desktop.pas | build
	$(FPC) $(FPCFLAGS) -oSnakeGame SnakeGame.pas

build/SnakeTerminal: SnakeTerminal.pas src/snake_engine.pas src/snake_cli.pas src/snake_terminal.pas | build
	$(FPC) $(FPCFLAGS) -oSnakeTerminal SnakeTerminal.pas

build/test_snake_engine: tests/test_snake_engine.pas src/snake_engine.pas | build
	$(FPC) $(FPCFLAGS) -otest_snake_engine tests/test_snake_engine.pas

local-build: build/SnakeGame build/SnakeTerminal

local-play: build/SnakeGame
	./build/SnakeGame

local-test: build/test_snake_engine
	./build/test_snake_engine

local-smoke: local-build
	python3 tests/smoke_terminal.py ./build/SnakeTerminal
	python3 tests/smoke_desktop.py ./build/SnakeGame

preview: | build
	$(DOCKER) build --target build -t pascal-snake-build:local .
	$(DOCKER) run --rm --network none -e SDL_VIDEODRIVER=dummy --mount "type=bind,src=$(CURDIR)/build,target=/captures" pascal-snake-build:local ./build/SnakeGame --snapshot /captures/play.bmp --scene play --seed 42 --no-audio
	magick build/play.bmp -strip docs/Preview.png
