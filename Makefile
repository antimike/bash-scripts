PROJECT_NAME = antimike-bash-scripts
PROJECT_DIR = `pwd`

INSTALL_DIRS = utils papis
DEST_DIR = /usr/local/bin
INSTALL_FILES = `find $(INSTALL_DIRS) -executable -type f 2>/dev/null`
ARCHIVE = $(PROJECT_NAME).tar.gz
SIG = $(PROJECT_NAME).asc

.PHONY : build sign clean tag release install uninstall all

$(ARCHIVE) :
	git archive --output=$(ARCHIVE) --prefix="$(PROJECT_DIR)/" HEAD

build : $(ARCHIVE)

sign : $(ARCHIVE)
	gpg --sign --detach-sign --armor "$(ARCHIVE)"

clean :
	rm -f "$(ARCHIVE)" "$(SIG)"

all :
	$(ARCHIVE) $(SIG)

tag :
	git tag v$(VERSION)
	git push --tags

release : $(ARCHIVE) $(SIG) tag

install :
	for file in $(INSTALL_FILES); do sudo ln -s "$$(realpath $$file)" "$(DEST_DIR)/$$(basename "$${file%.*}")"; done

uninstall :
	for file in $(INSTALL_FILES); do sudo rm -f "$(DEST_DIR)/$$(basename "$${file%.*}")"; done
