{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.linuwu-sense;
in
{
  options.hardware.linuwu-sense = {
    enable = lib.mkEnableOption "Linuwu-Sense kernel module for Acer Predator and Nitro laptops";

    package = lib.mkOption {
      type = lib.types.package;
      default = config.boot.kernelPackages.linuwu-sense;
      defaultText = lib.literalExpression "config.boot.kernelPackages.linuwu-sense";
      description = "The Linuwu-Sense kernel module package to use.";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Usernames to add to the 'linuwu_sense' group so they can control fan speeds,
        RGB keyboard modes, rear lightbars, battery limits, and lighting without root/sudo.
      '';
    };

    unloadOnShutdown = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to unload the linuwu_sense kernel module cleanly on system shutdown
        to prevent ACPI/WMI state issues across reboots.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ self.overlays.default ];

    boot.extraModulePackages = [ cfg.package ];
    boot.kernelModules = [ "linuwu_sense" ];
    boot.blacklistedKernelModules = [ "acer_wmi" ];

    users.groups.linuwu_sense = {
      members = cfg.users;
    };

    # Systemd tmpfiles to grant read/write access to sysfs control nodes for group linuwu_sense
    systemd.tmpfiles.rules = [
      "z /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi 0770 root linuwu_sense - -"
      "z /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/* 0770 root linuwu_sense - -"
      "z /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/*/* 0660 root linuwu_sense - -"
      "z /sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/*/*/* 0660 root linuwu_sense - -"
    ];

    # Apply permissions when the module or platform driver is loaded
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="module", KERNEL=="linuwu_sense", RUN+="${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=/sys/module/linuwu_sense"
      ACTION=="add", SUBSYSTEM=="platform", DRIVER=="acer-wmi", RUN+="${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=/sys/module/linuwu_sense"
    '';

    # Unload module cleanly on shutdown/reboot (equivalent to linuwu_sense.service)
    systemd.services.linuwu-sense-unload = lib.mkIf cfg.unloadOnShutdown {
      description = "Unload linuwu_sense kernel module at shutdown";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.kmod}/bin/rmmod linuwu_sense";
      };
    };
  };
}
