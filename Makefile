PATH := $(PATH):UTIL
SRC  := $(shell find . -type f -name '*.pl' | grep -v OFF/ | xargs grep -l '\#!' | cut -b3-)
BIN  := $(SRC:%.pl=%)

all: $(BIN)

%: %.pl *.pl
	perlpp $< > $@
	@chmod 755 $@

install: all
	makeinstall -f $(BIN)

clean:
	rm -fv $(BIN)

