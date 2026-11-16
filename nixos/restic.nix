{
  pkgs,
  ...
}: let
  backupMount = "/mnt/backup";
  backupUuid = "B075-954D";
in {
  fileSystems.${backupMount} = {
    device = "/dev/disk/by-uuid/${backupUuid}";
    fsType = "exfat";

    options = [
      "noauto"
      "nofail"
      "noatime"
      "uid=1000"
      "gid=100"
      "umask=0077"
      "x-systemd.device-timeout=10s"
    ];
  };

  services.restic.backups.external = {
    repository = "${backupMount}/restic/loonix";
    passwordFile = "/var/lib/restic/loonix-password";

    paths = [
      "/home/nielsing"
      "/etc/NetworkManager/system-connections"
    ];

    exclude = [
      "/home/nielsing/.cache"
      "/home/nielsing/.local/share/Trash"
      "/home/nielsing/.android"
      "/home/nielsing/.npm"
      "/home/nielsing/.rustup"
      "/home/nielsing/.go/pkg"
      "/home/nielsing/.cargo/registry"
      "/home/nielsing/Android/Sdk"
      "/home/nielsing/.BurpSuite/burpbrowser"
      "/home/nielsing/.codex/cache"
      "/home/nielsing/.codex/packages"
      "/home/nielsing/.codex/tmp"
      "/home/nielsing/.codex/.tmp"
      "/home/nielsing/.config/Slack/Cache"
      "/home/nielsing/.config/Slack/Code Cache"
      "/home/nielsing/.config/Slack/GPUCache"
      "/home/nielsing/.config/discord/Cache"
      "/home/nielsing/.config/discord/Code Cache"
      "/home/nielsing/.config/discord/GPUCache"

      # Per-project build outputs.
      "**/node_modules"
      "**/target"
      "**/.venv"
      "**/__pycache__"
      "**/.ruff_cache"
    ];

    extraBackupArgs = [
      "--one-file-system"
      "--tag"
      "weekly-external"
    ];

    initialize = true;
    inhibitsSleep = true;

    # No automatic schedule.
    timerConfig = null;

    pruneOpts = [
      "--keep-last 8"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 5"
    ];

    runCheck = true;
    checkOpts = [
      "--read-data-subset=5%"
    ];

    progressFps = 0.2;

    # Prevent initialization or backup onto the laptop when the drive
    # is missing or a different filesystem is mounted at this path.
    backupPrepareCommand = ''
      set -eu

      if ! ${pkgs.util-linux}/bin/mountpoint -q ${backupMount}; then
        echo "External backup drive is not mounted at ${backupMount}" >&2
        exit 1
      fi

      actual_uuid="$(
        ${pkgs.util-linux}/bin/findmnt \
          --noheadings \
          --output UUID \
          --target ${backupMount}
      )"

      if [ "$actual_uuid" != "${backupUuid}" ]; then
        echo "Wrong filesystem mounted at ${backupMount}: $actual_uuid" >&2
        exit 1
      fi
    '';
  };
}
