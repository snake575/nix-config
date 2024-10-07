# home-manager configuration

## Setup

Install Nix (standlone mode) with [nix-installer](https://github.com/DeterminateSystems/nix-installer)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Clone this repo to `~/.config/home-manager`

```bash
nix run nixpkgs#git -- git clone https://github.com/snake575/home-manager.git $HOME/.config/home-manager
```

Enable Home Manager

```bash
nix run nixpkgs#home-manager -- switch
```
