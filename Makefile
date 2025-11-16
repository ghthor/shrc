.PHONY: submodule_update
submodule_update:
	git submodule update --init --recursive

.PHONY: submodule_sync
submodule_sync:
	git submodule sync --recursive

.PHONY: syncthing_conflicts
syncthing_conflicts:
	@find . -name '*.sync*' |\
		tee $@
	@find . -name '*.sync-conflict*' |\
		tee -a $@
