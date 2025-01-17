let
  pkgs = (import ./nix/nixpkgs.nix).stable;
  lib = pkgs.lib;
  gitignoreSource = import ./nix/gitignore.nix { inherit lib; };
in
let
  selectedLinuxKernelPkg = pkgs.linux_6_2;
  kernel = pkgs.callPackage ./nix/kernel.nix { inherit selectedLinuxKernelPkg; };
  debugconModule = pkgs.callPackage ./nix/debugcon_module.nix { srcPath=./src-test; inherit gitignoreSource; inherit kernel; };
  testApp = pkgs.callPackage ./nix/test_app.nix { };
  initrd = pkgs.callPackage ./nix/initrd.nix { inherit kernel debugconModule testApp; };
  runQemuDemo = pkgs.callPackage ./nix/run_qemu_demo.nix { inherit initrd kernel; };
in
{
  inherit debugconModule;
  inherit runQemuDemo;
  inherit kernel;
  inherit initrd;
}
