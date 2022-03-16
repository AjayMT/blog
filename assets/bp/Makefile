
.PHONY: all
all: bp-random bp-same
bp-random: bp-random.c
bp-same: bp-same.c

bp-random bp-same:
	cc -O0 -o $@ $@.c

.PHONY: clean
clean:
	rm -fr bp-random bp-same
