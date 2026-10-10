{
  description = "Unofficial Linux Kernel Module for Acer Gaming Laptops (Linuwu-Sense)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      });
    in
    {
      overlays.default = final: prev: {
        linuxKernel = prev.linuxKernel // {
          packagesFor = kernel: (prev.linuxKernel.packagesFor kernel).extend (lpself: lpprev: {
            linuwu-sense = lpself.callPackage ./package.nix { };
          });
        };
      };

      packages = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.linuxPackages_latest.linuwu-sense;
        linuwu-sense = pkgs.linuxPackages_latest.linuwu-sense;
        linuwu-sense-zen = pkgs.linuxPackages_zen.linuwu-sense;
        linuwu-sense-lts = pkgs.linuxPackages.linuwu-sense;
      });

      devShells = forEachSupportedSystem ({ pkgs }:
        let
          kernel = pkgs.linuxPackages_latest.kernel;
        in {
          default = (pkgs.mkShell.override { stdenv = kernel.stdenv; }) {
            nativeBuildInputs = [
              pkgs.gnumake
              pkgs.bear
              pkgs.clang-tools
            ] ++ kernel.moduleBuildDependencies;

            shellHook = ''
              export KVER="${kernel.modDirVersion}"
              export KDIR="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
              echo "Linuwu-Sense kernel dev shell loaded for Linux ${kernel.modDirVersion}"
            '';
          };
        }
      );

      nixosModules = {
        default = import ./nixos-module.nix { inherit self; };
        linuwu-sense = self.nixosModules.default;
      };
    };
}
