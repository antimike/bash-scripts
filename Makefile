subdirs = include misc utils
DESTDIR = /usr/local/bin
scripts = $(wildcard *.sh)
paths=$(foreach script, $(scripts), $(realpath $(script)) )	# Trailing space
names=$(foreach script, $(scripts), $(basename $(script)))
dests=$(foreach name, $(names), $(DESTDIR)/$(name))
cmd=sudo ln -s # Trailing space
cmds=$(foreach pair, $(join $(paths), $(dests)), $(cmd) $(pair); )


.PHONY: all

all :
	# for script in $(scripts); do sudo ln -s "$(realpath "$$script")" "$(DESTDIR)/$${script%.*}"; done
	# $(realpath $(scripts))
	$(cmds)

clean : 
	$(foreach dest, $(dests), sudo rm -f $(dest); )	


