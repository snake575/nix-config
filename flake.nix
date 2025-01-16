{
  description = "Home Manager configuration of snake575";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
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
        "snake575@nomad-macbook" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.aarch64-darwin;
          modules = [ ./home/macos.nix ];
        };
      };
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
    };
}
