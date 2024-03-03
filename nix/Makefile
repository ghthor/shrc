.DEFAULT_GOAL := $(shell hostname)

.PHONY: thornix cryptnix

thornix:
	sudo nixos-rebuild switch --flake '.#thornix' --show-trace

cryptnix:
	sudo nixos-rebuild switch --flake '.#cryptnix' --show-trace
