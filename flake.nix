{
  description = "Home Manager configuration of snake575";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    claude-code.url = "github:sadjow/claude-code-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      systems,
      claude-code,
      ...
    }:
    let
      lib = nixpkgs.lib // home-manager.lib;
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            claude-code.overlays.default
            (final: prev: {
              happy-coder = final.callPackage ./packages/happy-coder.nix { };
            })
          ];
        }
      );
    in
    {
      homeConfigurations = {
        snake575 = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          modules = [ ./home/linux.nix ];
        };
        "snake575@NOMAD-X670" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          modules = [ ./home/wsl.nix ];
        };
        "snake575@NOMAD-MacBook" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.aarch64-darwin;
          modules = [ ./home/macos.nix ];
        };
      };
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
    };
}
