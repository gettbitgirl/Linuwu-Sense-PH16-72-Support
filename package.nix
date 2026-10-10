{
  lib,
  kernel,
  kernelModuleMakeFlags ? [ ],
}:

kernel.stdenv.mkDerivation {
  pname = "linuwu-sense";
  version = "0.1.0-${kernel.version}";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Makefile
      ./src
    ];
  };

  hardeningDisable = [
    "pic"
    "format"
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KVER=${kernel.modDirVersion}"
  ];

  installPhase = ''
    runHook preInstall
    install -D -m 644 src/linuwu_sense.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/linuwu_sense.ko
    runHook postInstall
  '';

  meta = {
    description = "Unofficial Linux Kernel Module for Acer Gaming Laptops (Predator and Nitro)";
    homepage = "https://github.com/0x7375646F/Linuwu-Sense";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
