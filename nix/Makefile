.DEFAULT_GOAL := $(shell hostname)

.PHONY: thornix cryptnix nydus

USE_FLAKE ?= 0

thornix:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild switch --flake '.#thornix' --show-trace; \
	else \
		sudo rsync -r ./thornix/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo rsync -r ./packages/ /etc/nixos/packages/; \
		sudo nixos-rebuild -I nixpkgs=/home/ghthor/src/nixpkgs -I nixos-config=/etc/nixos/configuration.nix switch --show-trace; \
	fi

cryptnix:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild switch --flake '.#cryptnix' --show-trace; \
	else \
		sudo rsync -r ./cryptnix/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo rsync -r ./packages/ /etc/nixos/packages/; \
		sudo nixos-rebuild -I nixpkgs=/home/ghthor/src/nixpkgs -I nixos-config=/etc/nixos/configuration.nix switch --show-trace; \
	fi

nydus:
	if [ $(USE_FLAKE) -eq 1 ]; then \
		sudo nixos-rebuild switch --flake '.#nydus' --show-trace; \
	else \
		sudo rsync -r ./nydus/ /etc/nixos/; \
		sudo rsync -r ./modules/ /etc/nixos/modules/; \
		sudo nixos-rebuild -I nixos-config=/etc/nixos/configuration.nix switch --show-trace; \
	fi
