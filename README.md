# Nix configurations

## Setup

Install Nix (standalone mode) with [nix-installer](https://github.com/DeterminateSystems/nix-installer)

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

sudo chsh -s $(which zsh) $(whoami)
```

Copy Ghostty terminfo to a remote machine

```bash
infocmp -x | ssh YOUR-SERVER -- tic -x -
```

## Updating

Update the locked inputs, review the [Home Manager release notes](https://nix-community.github.io/home-manager/release-notes/index.html)
and [Nixpkgs release notes](https://nixos.org/manual/nixpkgs/unstable/release-notes),
then evaluate every platform and build the current platform's home configuration:

```bash
nix flake update
nix flake check --all-systems --no-build
nix flake check
```

The checks include the macOS, Linux, and WSL home configurations. Building other
platforms requires a matching builder. Review major runtime upgrades before
switching; projects that need specific versions should pin them in their own shells.

Apply the checked configuration with `home-manager switch --flake .`.
Keep `home.stateVersion` unchanged unless deliberately migrating the compatibility
defaults described in the Home Manager release notes.
