# WSL on NOMAD-X670

This repo records Windows networking/firewall and Ubuntu service decisions, while
Home Manager activation manages the user environment. Host changes are applied
separately.

Physical devices on the LAN need to reach development servers in WSL. Windows also
needs access through the host's IPv4 addresses. These goals explain the settings
in Windows `%UserProfile%\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
[experimental]
hostAddressLoopback=true
```

LAN access also depends on separate Hyper-V inbound firewall exceptions; Windows
application firewall rules do not replace them. VPN connectivity comes from the
Windows host through mirrored networking.

SSH authentication and Git signing use Windows tools so both environments share
credentials. A separate Linux key or agent setup would split that ownership.

The Windows desktop application owns its WSL agent backend and remote-access
processes, with dynamically allocated backend ports. Preserve that ownership when
changing startup or firewall configuration. Direct inbound desktop access is
scoped to trusted Private networks.

User systemd supports agent process scopes. A failed user manager is a fault even
when shell sessions still work.

`wsl-pro.service` is intentionally disabled while the Windows Pro agent is unused.
