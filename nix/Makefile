.DEFAULT_GOAL := home

.PHONY: home system cryptnix steamnix nydus

USE_FLAKE ?= 0

CMD ?= build
SYSTEM ?= $(shell uname -s)
# Bootstrap nh from the flake until it is available in the active Home Manager profile.
NH ?= $(shell if command -v nh >/dev/null 2>&1; then printf '%s' nh; else printf '%s' 'nix run .#nh --'; fi)

ifeq ($(SYSTEM),Darwin)
HOME_SYSTEM        := aarch64-darwin
HOME_CONFIGURATION := willowens
else ifeq ($(SYSTEM),Linux)
HOME_SYSTEM        := x86_64-linux
HOME_CONFIGURATION := ghthor
else
$(error Unsupported SYSTEM '$(SYSTEM)'; expected Darwin or Linux)
endif

home:
	@printf 'Home Manager: SYSTEM=%s CONFIGURATION=%s CMD=%s\n' '$(SYSTEM)' '$(HOME_CONFIGURATION)' '$(CMD)'
	$(NH) home $(CMD) --configuration '$(HOME_CONFIGURATION)' .

system:
	sudo rsync -r ./thornix/ /etc/nixos/; \
	sudo rsync -r ./modules/ /etc/nixos/modules/; \
	sudo rsync -r ./packages/ /etc/nixos/packages/; \
	sudo nixos-rebuild \
	  -I nixpkgs=/home/ghthor/src/nixpkgs \
	  -I nixos-config=/etc/nixos/configuration.nix \
	  $(CMD) --show-trace

cryptnix:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild $(CMD) --flake '.#cryptnix' --show-trace; \
	else \
		sudo rsync -r ./cryptnix/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo rsync -r ./packages/ /etc/nixos/packages/; \
		sudo nixos-rebuild -I nixpkgs=/home/ghthor/src/nixpkgs -I nixos-config=/etc/nixos/configuration.nix $(CMD) --show-trace; \
	fi


steamnix:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild $(CMD) --flake '.#steamnix' --show-trace; \
	else \
		sudo rsync -r ./steamnix/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo rsync -r ./packages/ /etc/nixos/packages/; \
		sudo nixos-rebuild $(CMD) --show-trace; \
	fi


nydus:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild $(CMD) --flake '.#nydus' --show-trace; \
	else \
		sudo rsync -r ./nydus/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo nixos-rebuild -I nixos-config=/etc/nixos/configuration.nix $(CMD) --show-trace; \
	fi
