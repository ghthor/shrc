.PHONY: submodule_update
submodule_update:
	git submodule update --init --recursive

.PHONY: submodule_sync
submodule_sync:
	git submodule sync --recursive
