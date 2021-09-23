.PHONY: install_tools
install_tools: tools_pkg.list
	cat $< | yay -Sy --needed -
