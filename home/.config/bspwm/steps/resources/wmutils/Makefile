default: build

.PHONY: build
build:
	cargo build -r

.PHONY: run
run:
	cargo run

.PHONY: dist
dist: build
	cp target/release/wlist ~/bin/
