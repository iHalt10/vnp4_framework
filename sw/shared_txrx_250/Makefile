.PHONY: all clean clean-all

CC     := gcc
CFLAGS := -Wall -Wextra -O2 -g
LIBS   := driver/lib/libvitisnetp4drv.a -lm

INCLUDE_PATHS := -I.
CFLAGS        += $(INCLUDE_PATHS)

COMMON_SRCS := $(shell find common/src -type f -name "*.c")
MAIN_SRCS   := $(shell find src/cmd -maxdepth 1 -type f -name "*.c")
MODULE_SRCS := $(shell find src -type f -name "*.c" -not -path "src/cmd/*")
TARGETS     := $(addprefix bin/,$(notdir $(basename $(MAIN_SRCS))))
SUB_OBJS    := $(COMMON_SRCS:.c=.o) $(MODULE_SRCS:.c=.o)

all: $(TARGETS)

bin/%: src/cmd/%.o $(SUB_OBJS)
	@mkdir -p bin
	$(CC) $(CFLAGS) -o $@ $< $(SUB_OBJS) $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf bin

clean-all: clean
	rm -rf driver
