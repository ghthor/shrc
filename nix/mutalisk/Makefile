# switch: flake.lock_sync
switch:
	if [ "$$(hostname)" != "VOLTUS-MAC-GVQX2XQ2C6" ]; then echo "$$(hostname) != VOLTUS-MAC-GVQX2XQ2C6"; fi
	nix run '.#home-manager' -- switch --flake .

flake.lock_sync:
	go run ./cmd/sync-nixpkgs/main.go --from flake.lock.upstream --to flake.lock
