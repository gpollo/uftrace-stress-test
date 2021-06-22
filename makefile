CFLAGS=-g -Wall -O0 -pthread

all: \
	build/main-none \
	build/main-pg \
	build/main-fentry \
	build/main-xray \
	build/main-none-pause \
	build/main-pg-pause \
	build/main-fentry-pause \
	build/main-xray-pause

build/main-none: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@

build/main-pg: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@ -pg

build/main-fentry: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@ -pg -mfentry -mnop-mcount -no-pie -fno-pic

build/main-xray: source/main.c
	@mkdir -p build
	clang $(CFLAGS) $< -o $@ -fxray-instrument -fxray-instruction-threshold=1

build/main-none-pause: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@ -DWITH_PAUSE

build/main-pg-pause: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@ -DWITH_PAUSE -pg

build/main-fentry-pause: source/main.c
	@mkdir -p build
	gcc $(CFLAGS) $< -o $@ -DWITH_PAUSE -pg -mfentry -mnop-mcount -no-pie -fno-pic

build/main-xray-pause: source/main.c
	@mkdir -p build
	clang $(CFLAGS) $< -o $@ -DWITH_PAUSE -fxray-instrument -fxray-instruction-threshold=1
