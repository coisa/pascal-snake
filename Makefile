FPC ?= fpc
FPCFLAGS = -Mobjfpc -Sh -O2 -g -gl -Cr -Co -Ci -Sa -vew -Fusrc -FUbuild -FEbuild
IMAGE ?= pascal-snake:local
TEST_IMAGE ?= pascal-snake-test:local
DOCKER ?= docker

.PHONY: help image test play smoke local-build local-test local-smoke

help:
	@printf '%s\n' 'make test   - compile and run Pascal + PTY tests in Docker' 'make image  - build the playable image (also runs Pascal tests)' 'make play   - build and play in an interactive terminal' 'make smoke  - test the packaged game through a synthetic PTY' 'make local-build local-test local-smoke - use an installed FPC + Python'

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

build/SnakeGame: SnakeGame.pas src/snake_engine.pas src/snake_terminal.pas | build
	$(FPC) $(FPCFLAGS) -oSnakeGame SnakeGame.pas

build/test_snake_engine: tests/test_snake_engine.pas src/snake_engine.pas | build
	$(FPC) $(FPCFLAGS) -otest_snake_engine tests/test_snake_engine.pas

local-build: build/SnakeGame

local-test: build/test_snake_engine
	./build/test_snake_engine

local-smoke: local-build
	python3 tests/smoke_terminal.py ./build/SnakeGame
