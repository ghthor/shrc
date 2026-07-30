.DEFAULT_GOAL := home

.PHONY: home system cryptnix steamnix nydus

USE_FLAKE ?= 0

CMD ?= build

home:
	home-manager $(CMD) --flake '.#ghthor' --show-trace

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
