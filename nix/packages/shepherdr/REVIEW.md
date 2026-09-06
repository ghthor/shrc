# Shepherdr security review and deployment notes

Repository reviewed: `https://github.com/luiscleto/shepherdr.git`

Local clone: `/home/ghthor/src/shepherdr/`

Reviewed commit: `b04176b16de2e9547421f0e9646d596a2343bc8e` (`v0.2.0`)

## Security review

### Scope and threat model

The review focused on a deployment where Shepherdr is not exposed to the public internet:

- Shepherdr listens on `127.0.0.1:8787`.
- Tailscale Serve proxies the service to a private HTTPS tailnet hostname.
- Tailscale Funnel/public ingress is not enabled.
- Only trusted tailnet users and devices should be able to reach the hostname.
- Passkey authentication remains enabled.

### Overall assessment

No obvious critical or high-severity issue was found for this private-tailnet deployment model. The code shows a strong security posture around passkeys, origin validation, session revocation, local file permissions, terminal targeting, and upload handling.

This assessment assumes that Tailscale ACLs are correctly configured and that the host OS account running Herdr/Shepherdr is trusted.

### Positive security controls observed

- The application refuses non-loopback listen addresses.
- Tailscale Serve can provide the required HTTPS origin without exposing the local port directly.
- WebAuthn/passkey authentication is enforced independently of Tailscale reachability.
- Host and origin checks prevent use through arbitrary hostnames or proxy destinations.
- Session cookies are `Secure`, `HttpOnly`, `SameSite=Strict`, and use the `__Host-` prefix.
- Mutating requests require same-origin JSON requests and bounded request bodies.
- Terminal and workspace operations are authorized through the authenticated session and checked against current Herdr state.
- Revoking a trusted device invalidates its sessions and active connections.
- Terminal WebSocket input uses strict schemas, bounded sizes, and command allowlisting.
- Uploads use owner-only directories/files, exclusive creation, path sanitization, ownership markers, and rollback handling.
- Push notification endpoints are HTTPS-only and checked against publicly routable addresses to mitigate SSRF.
- The application sends CSP, `X-Content-Type-Options`, `X-Frame-Options`, and `Referrer-Policy` headers.
- Frontend rendering uses text APIs rather than `innerHTML` or `eval`-style sinks.
- Persistent access and notification state is stored with restrictive file permissions.

### Findings and residual risks

#### Low: Go vulnerability scanning was not completed

`npm audit` reported no vulnerabilities. Go tests and `go vet` passed, but `govulncheck` was not installed, so Go dependency vulnerability scanning was not completed.

Recommendation: run `govulncheck ./...` in CI or during release verification.

#### Low: `-no-sign-in` trusts the entire reachable network

With:

```sh
shepherdr -no-sign-in
```

any client able to reach the Tailscale service has operator authority. This may be acceptable for a tightly controlled personal tailnet, but a compromised or misplaced tailnet device could control terminals and workspaces.

Recommendation: keep passkey authentication enabled.

#### Informational: unsigned macOS releases

The README states that macOS binaries are unsigned. Checksums help, but signed/notarized artifacts would provide stronger provenance. This is not an immediate blocker for a private-tailnet runtime deployment.

#### Informational: release CI lacks an automated Go SCA step

The release workflow runs tests, builds, and checksum verification, but does not appear to run `govulncheck` or another Go software-composition analysis tool.

### Important operational controls

1. Keep Shepherdr listening on loopback only.
2. Use Tailscale Serve, not Tailscale Funnel.
3. Restrict tailnet access with Tailscale ACLs/grants.
4. Keep passkey sign-in enabled.
5. Treat the host OS account and Herdr session as highly privileged.
6. Confirm Shepherdr is not separately exposed through a LAN interface, reverse proxy, or port-forward.

### Host compromise boundary

Shepherdr runs as the same OS account as Herdr and can control Herdr terminals, create or remove workspaces/worktrees, write uploaded files, and access local application state. A process or user that compromises that OS account is effectively outside Shepherdr's application-level security boundary.

## Questions and answers

### What does `-public-origin` mean?

`-public-origin` is the canonical browser address where protected Shepherdr is expected to be used. Despite the name, it does not mean public internet exposure. In a Tailscale deployment, it should be the private HTTPS Tailscale hostname.

Example:

```sh
tailscale serve --bg 8787
shepherdr \
  -public-origin https://shepherdr.example-tailnet.ts.net \
  -vapid-contact mailto:you@example.com
```

The intended request path is:

```text
Browser
  |
  v
https://shepherdr.example-tailnet.ts.net
  |
  | Tailscale Serve
  v
127.0.0.1:8787
  |
  v
Shepherdr
```

It controls several security-sensitive identities:

- **WebAuthn/passkey identity:** passkeys are registered for this hostname and are not automatically valid at `localhost`, `127.0.0.1`, an IP address, or another hostname.
- **Host validation:** protected requests must use the configured host.
- **Origin/CSRF validation:** state-changing browser requests must have an origin matching the configured HTTPS origin.
- **Persistent deployment identity:** the origin is stored on initial protected setup and later starts must use the same origin.

Use the exact HTTPS hostname supplied by Tailscale Serve, without a trailing slash:

```sh
-public-origin https://your-machine.your-tailnet.ts.net
```

Accepted examples:

```text
https://shepherdr.example-tailnet.ts.net
https://shepherdr.example-tailnet.ts.net:8443
```

Rejected examples include:

```text
http://shepherdr.example-tailnet.ts.net
https://Shepherdr.example-tailnet.ts.net
https://192.168.1.20
https://localhost
https://shepherdr.example-tailnet.ts.net/
https://shepherdr.example-tailnet.ts.net/app
https://shepherdr.example-tailnet.ts.net:443
```

The name “public-origin” means the externally reachable browser origin from the application's perspective; it does not imply that the origin is publicly reachable on the internet.

### What does `-vapid-contact mailto:you@example.com` mean?

This configures browser push notifications. VAPID means **Voluntary Application Server Identification**. The value identifies Shepherdr to Web Push services and gives them an operator contact address.

It does not:

- create a Shepherdr account;
- authenticate users;
- send a confirmation email;
- expose the address in the Shepherdr UI;
- make Shepherdr publicly reachable; or
- affect Tailscale access or passkey authentication.

Replace the example with a real operator contact:

```sh
-vapid-contact mailto:your-real-email@example.com
```

An HTTPS URL is also accepted:

```sh
-vapid-contact https://example.com/contact
```

On initial setup, Shepherdr validates the value, generates a VAPID key pair locally, and stores the contact and private key in its notification state, normally:

```text
~/.config/shepherdr/notifications.json
```

The contact is not a secret; the VAPID private key is. The state file is intended to be owner-only.

The flag is optional. Without it, core terminal and workspace features still work, but browser push notifications are unavailable. The value is persisted and generally only needs to be supplied once.

In a private Tailscale setup, inbound access can remain Tailscale-only, but push delivery requires outbound HTTPS access to the browser's Web Push service endpoint. Notification payloads are encrypted for the browser by Web Push. The push provider can see the VAPID contact and the delivery endpoint.

A reasonable command for this deployment is:

```sh
shepherdr \
  -public-origin https://your-machine.your-tailnet.ts.net \
  -vapid-contact mailto:your-real-email@example.com
```

## Verification performed

The following checks passed:

- `go test ./...`
- `go vet ./...`
- `npm ci --ignore-scripts`
- `npm audit` — no reported vulnerabilities
- `npm test --prefix web` — 120 tests passed
- `npm run typecheck --prefix web`
- `npm run build --prefix web`
- Verified the browser build produced no tracked `web/dist` changes
- `git diff --check`

No files were modified in the cloned Shepherdr repository during the review.
