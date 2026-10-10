{
  description = "Unofficial Linux Kernel Module for Acer Gaming Laptops (Linuwu-Sense)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      mkModule = pkgs: kernel: pkgs.stdenv.mkDerivation {
        pname = "linuwu-sense";
        version = "0.1.0";
        src = self;

        nativeBuildInputs = [ pkgs.gnumake ] ++ kernel.moduleBuildDependencies;

        KDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
        KVER = kernel.modDirVersion;

        buildPhase = ''
          runHook preBuild
          make all KDIR="$KDIR" KVER="$KVER"
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -D -m 644 src/linuwu_sense.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/linuwu_sense.ko
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Unofficial Linux Kernel Module for Acer Gaming Laptops";
          license = licenses.gpl2Plus;
          platforms = platforms.linux;
        };
      };
    in
    {
      packages = forEachSupportedSystem ({ pkgs }:
        let
          mod = mkModule pkgs pkgs.linuxPackages_latest.kernel;
        in {
          default = mod;
          linuwu-sense = mod;
        }
      );

      devShells = forEachSupportedSystem ({ pkgs }:
        let
          kernel = pkgs.linuxPackages_latest.kernel;
        in {
          default = pkgs.mkShell {
            nativeBuildInputs = [ pkgs.gnumake ] ++ kernel.moduleBuildDependencies;
            shellHook = ''
              export KVER="${kernel.modDirVersion}"
              export KDIR="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
              echo "Linuwu-Sense kernel dev shell loaded for Linux ${kernel.modDirVersion}"
            '';
          };
        }
      );

      nixosModules.default = { config, pkgs, ... }: {
        boot.extraModulePackages = [
          (mkModule pkgs config.boot.kernelPackages.kernel)
        ];
        boot.blacklistedKernelModules = [ "acer_wmi" ];
        boot.kernelModules = [ "linuwu_sense" ];
      };
    };
}
