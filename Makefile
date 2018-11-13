PATH := $(PATH):UTIL
SRC  := $(shell find . -type f -name '*.pl' | grep -v OFF/ | xargs grep -l '\#!' | cut -b3-)
BIN  := $(SRC:%.pl=%)

all: $(BIN) README.md

%: %.pl *.pl
	perlpp $< > $@
	@chmod 755 $@

install: all
	makeinstall -f $(BIN)

clean:
	rm -fv $(BIN)

push: clean
	git add .
	git commit -m update
	git status
	git push -f origin master

mrproper: clean
	rm -fv README.md

README.md: evgen
	$< -h > /tmp/help2md.tmp
	help2md /tmp/help2md.tmp > $@

