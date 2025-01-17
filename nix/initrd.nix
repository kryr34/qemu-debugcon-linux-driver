# Nix derivation that creates a minimal initrd with tools from busybox.
# The initrd sets up a minimal typical Linux environment and inserts
# the debugcon out-of-tree kernel module.

{ pkgs
, lib
, debugconModule
, kernel
, testApp
}:

let
  debugconKernelMod = "${debugconModule}/lib/modules/6.2.0/extra/debugcon.ko";
  kernelModDir = "${kernel}/lib/modules/6.2.0/";
  testAppBin = "${testApp}/bin/test_app";
in
pkgs.makeInitrd {
  contents = [{
    object = pkgs.writers.writeBash "init" ''
      set -eu
      export PATH=${lib.makeBinPath
        ([
           # Basic shell dependencies
           pkgs.bashInteractive
           pkgs.busybox
           pkgs.git
           # If you want, you can add other utilities here.
           # They might require more kernel features.
           # pkgs.fd
        ])
      }

      mkdir -p /proc /sys /tmp /run /var
      mount -t proc none /proc
      mount -t sysfs none /sys
      mount -t tmpfs none /tmp
      mount -t tmpfs none /run

      mkdir -p /lib/modules/6.2.0
      ln -s ${kernelModDir}/* /lib/modules/6.2.0
      mkdir -p /lib/modules/6.2.0/extra
      ln -s ${debugconKernelMod} /lib/modules/6.2.0/extra

      # Insert the debugcon kernel module.
      insmod ${debugconKernelMod}
      depmod

      # Create device nodes.
      mdev -s

      echo -n "/dev/debugcon: "
      ls /dev | grep -q debugcon && echo EXISTS || echo 'NOT FOUND'

      ${testAppBin}

      # Enter bash (the root shell)
      setsid cttyhack bash

      poweroff -f
    '';
    symlink = "/init";
  }];
}
