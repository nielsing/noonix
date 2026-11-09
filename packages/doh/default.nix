{
  lib,
  writeShellApplication,
  coreutils,
  doctl,
  gawk,
  gnugrep,
  gnused,
  iproute2,
  jq,
  nftables,
  openssh,
  sudo,
  util-linux,
  wireguard-tools,
}:
writeShellApplication {
  name = "doh";

  runtimeInputs = [
    coreutils
    doctl
    gawk
    gnugrep
    gnused
    iproute2
    jq
    nftables
    openssh
    sudo
    util-linux
    wireguard-tools
  ];

  text = ''
    readonly DOH_DEV_CLOUD_INIT=${./cloud-init/dev.yaml}
    readonly DOH_ROUTER_CLOUD_INIT=${./cloud-init/router.yaml}

    ${builtins.readFile ./doh.sh}
  '';

  meta = {
    description = "Create and destroy ephemeral Droplets";
    license = lib.licenses.mit;
    mainProgram = "doh";
    platforms = lib.platforms.linux;
  };
}
