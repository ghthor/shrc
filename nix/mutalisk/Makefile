# switch: flake.lock_sync
switch:
	if [ "$$(hostname)" != "VOLTUS-MAC-GVQX2XQ2C6" ]; then echo "$$(hostname) != VOLTUS-MAC-GVQX2XQ2C6"; fi
	nix run '.#home-manager' -- switch --flake .

flake.lock_sync:
	go run ./cmd/sync-nixpkgs/main.go --from flake.lock.upstream --to flake.lock

tabby_bootout:
	launchctl bootout gui/$$(id -u) ~/Library/LaunchAgents/com.ghthor.tabby.plist

tabby_reload:
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/com.ghthor.tabby.plist

tabby_restart:
	launchctl kickstart -k gui/$$(id -u)/com.ghthor.tabby

tabby_logs:
	log stream --predicate 'eventMessage contains "com.ghthor.tabby"' --info
