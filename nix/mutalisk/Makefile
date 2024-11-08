switch: flake.lock_sync
	if [ "$(hostname)" != "mutalisk.local" ]; then echo "$(hostname) != mutalisk.local"; fi
	nix run '.#home-manager' -- switch --flake .

flake.lock_sync:
	go run ./cmd/sync-nixpkgs/main.go --from flake.lock.upstream --to flake.lock
