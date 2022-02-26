.PHONY: install_tools
install_tools: tools_pkg.list
	cat $< | yay -Sy --needed -

.PHONY: submodule_update
submodule_update:
	git submodule update --init --recursive
