# Nix configurations

## Setup

Install Nix (standlone mode) with [nix-installer](https://github.com/DeterminateSystems/nix-installer)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Clone this repo to `~/.config/home-manager`

```bash
nix run nixpkgs#git -- clone https://github.com/snake575/nix-config.git $HOME/.config/home-manager
```

Enable [Home Manager](https://github.com/nix-community/home-manager)

```bash
nix run nixpkgs#home-manager -- switch
```

Change the default shell to `zsh`

```bash
echo $(which zsh) | sudo tee -a /etc/shells

chsh -s $(which zsh)
```