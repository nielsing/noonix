set -o errexit
set -o nounset
set -o pipefail

readonly DOH_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/doh"
readonly DOH_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/doh"
readonly DOH_CONFIG_FILE="${DOH_CONFIG_FILE:-$DOH_CONFIG_HOME/config.json}"
readonly DOH_MANAGED_TAG="doh-managed"
readonly DOH_WG_INTERFACE="doh-router"

TEMP_FILES=()

cleanup() {
  local path

  for path in "${TEMP_FILES[@]}"; do
    if [[ -n "$path" && -f "$path" ]]; then
      rm -f -- "$path"
    fi
  done
}

trap cleanup EXIT

die() {
  printf 'doh: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'doh: warning: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage:
  doh init
  doh doctor [--region <slug>]
  doh sizes [--region <slug>]
  doh keys
  doh list
  doh <dev|router> up [--region <slug>] [--name <hostname>] [--user <name>] [--connect]
  doh <dev|router> ssh [command ...]
  doh <dev|router> ip
  doh <dev|router> status
  doh <dev|router> down [--yes]
  doh <dev|router> forget [--yes]
  doh dev open <port|range> [--protocol <tcp|udp>] [--source <cidr>]
  doh dev close <port|range> [--protocol <tcp|udp>] [--source <cidr>]
  doh dev ports
  doh router connect
  doh router disconnect

Typical first-time setup:
  doctl auth init
  doh init
  doh keys
  doh sizes
  $EDITOR ~/.config/doh/config.json
  doh doctor

The router is an IPv4 full-tunnel WireGuard gateway. `router up` creates and
configures it; add --connect to activate the tunnel immediately. `down`
disconnects the tunnel before destroying the Droplet.

The login user defaults to `doh`. If --name is omitted, an interactive shell
prompts for the Droplet hostname; an empty answer defaults to `dev` or `router`.

Development Droplets allow only SSH inbound by default. `dev open` and
`dev close` manage additional DigitalOcean Cloud Firewall rules. The default
rule is TCP from 0.0.0.0/0.

Configuration and state:
  Config: $XDG_CONFIG_HOME/doh/config.json (default: ~/.config/doh/config.json)
  State:  $XDG_STATE_HOME/doh             (default: ~/.local/state/doh)

Set DOH_CONFIG_FILE to use a different configuration file.
EOF
}

ensure_private_directory() {
  local directory=$1

  if [[ ! -d "$directory" ]]; then
    install -d -m 0700 "$directory"
  fi
}

init_config() {
  local temporary

  if [[ -e "$DOH_CONFIG_FILE" ]]; then
    die "configuration already exists at $DOH_CONFIG_FILE"
  fi

  ensure_private_directory "$DOH_CONFIG_HOME"
  temporary=$(mktemp "$DOH_CONFIG_HOME/.config.json.XXXXXX")
  TEMP_FILES+=("$temporary")

  jq -n '{
      image: "ubuntu-26-04-x64",
      project_id: "",
      ssh_key: "46684489",
      ssh_user: "doh",
      ssh_cidr: "0.0.0.0/0",
      profiles: {
        router: {
          size: "s-1vcpu-512mb-10gb",
          max_monthly_price: 4,
          wireguard_port: 51820
        },
        dev: {
          size: "s-4vcpu-8gb",
          max_monthly_price: 48
        }
      }
    }' >"$temporary"

  chmod 0600 "$temporary"
  mv -- "$temporary" "$DOH_CONFIG_FILE"

  printf 'Created %s\n\n' "$DOH_CONFIG_FILE"
  printf 'The configured SSH key is DigitalOcean key 46684489 (Niels).\n'
  printf 'Review the user, price limits, and size slugs before use.\n'
}

config_value() {
  local expression=$1

  jq -er "$expression" "$DOH_CONFIG_FILE"
}

config_optional() {
  local expression=$1

  jq -r "$expression // empty" "$DOH_CONFIG_FILE"
}

load_config() {
  [[ -f "$DOH_CONFIG_FILE" ]] || die "missing $DOH_CONFIG_FILE; run: doh init"
  jq -e 'type == "object"' "$DOH_CONFIG_FILE" >/dev/null || die "invalid JSON in $DOH_CONFIG_FILE"

  IMAGE=$(config_value '.image | strings | select(length > 0)')
  PROJECT_ID=$(config_optional '.project_id | strings')
  SSH_KEY=$(config_value '.ssh_key | strings | select(length > 0)')
  SSH_USER=$(config_value '.ssh_user | strings | select(length > 0)')
  SSH_CIDR=$(config_value '.ssh_cidr | strings | select(length > 0)')

  [[ "$IMAGE" =~ ^[a-zA-Z0-9._-]+$ ]] || die "image contains unsupported characters"
  validate_ssh_user "$SSH_USER"
  [[ "$SSH_CIDR" =~ ^[0-9a-fA-F:./]+$ ]] || die "ssh_cidr must be a single IPv4 or IPv6 CIDR"
}

validate_ssh_user() {
  local user=$1

  [[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "$user is not a valid Linux user name"
  [[ "$user" != "root" ]] || die "the SSH user must not be root"
}

validate_droplet_name() {
  local name=$1
  local label
  local labels=()

  [[ ${#name} -le 253 ]] || die "Droplet name is longer than 253 characters"
  IFS='.' read -r -a labels <<<"$name"
  [[ ${#labels[@]} -gt 0 ]] || die "Droplet name must not be empty"

  for label in "${labels[@]}"; do
    [[ ${#label} -ge 1 && ${#label} -le 63 ]] \
      || die "each Droplet name label must contain between 1 and 63 characters"
    [[ "$label" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] \
      || die "$name is not a valid hostname"
  done
}

select_droplet_name() {
  local profile=$1
  local requested_name=$2
  local name_was_provided=$3
  local selected

  if [[ "$name_was_provided" == "true" ]]; then
    selected=$requested_name
  elif [[ -t 0 ]]; then
    read -r -p "Droplet name [$profile]: " selected
    selected=${selected:-$profile}
  else
    selected=$profile
  fi

  validate_droplet_name "$selected"
  DROPLET_NAME=$selected
}

load_profile() {
  local profile=$1

  PROFILE_SIZE=$(config_value ".profiles.$profile.size | strings | select(length > 0)")
  PROFILE_MAX_PRICE=$(config_value ".profiles.$profile.max_monthly_price | numbers | select(. > 0)")

  if [[ "$PROFILE_SIZE" != "auto" ]] && [[ ! "$PROFILE_SIZE" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    die "$profile size contains unsupported characters"
  fi

  if [[ "$profile" == "router" ]]; then
    WG_PORT=$(config_value '.profiles.router.wireguard_port | numbers | select(. >= 1 and . <= 65535 and floor == .)')
  fi
}

doctl_context() {
  doctl "$@"
}

check_api_json() {
  local json=$1
  local operation=$2
  local error

  jq -e . >/dev/null <<<"$json" || die "DigitalOcean returned invalid JSON while $operation"
  error=$(jq -r '
    if type == "object" and (.errors? | type == "array") then
      [.errors[] | .detail // tostring] | join("; ")
    else
      empty
    end
  ' <<<"$json")
  [[ -z "$error" ]] || die "DigitalOcean API error while $operation: $error"
}

select_region() {
  local requested_region=${1:-}
  local regions_json selected

  regions_json=$(doctl_context compute region list --output json)
  check_api_json "$regions_json" "listing regions"

  if [[ -n "$requested_region" ]]; then
    [[ "$requested_region" =~ ^[a-z0-9-]+$ ]] || die "region contains unsupported characters"
    jq -e --arg region "$requested_region" \
      '.[] | select(.slug == $region and .available == true)' \
      <<<"$regions_json" \
      >/dev/null \
      || die "region $requested_region is not currently available"
    REGION=$requested_region
    return
  fi

  [[ -t 0 ]] || die "region selection requires a terminal; pass --region <slug>"
  printf 'Available DigitalOcean regions:\n'
  jq -r '.[] | select(.available == true) | "  \(.slug)\t\(.name)"' <<<"$regions_json" \
    | column -t -s $'\t'
  printf '\n'
  read -r -p 'Region: ' selected
  [[ "$selected" =~ ^[a-z0-9-]+$ ]] || die "invalid region slug"
  jq -e --arg region "$selected" \
    '.[] | select(.slug == $region and .available == true)' \
    <<<"$regions_json" \
    >/dev/null \
    || die "region $selected is not currently available"
  REGION=$selected
}

state_file() {
  printf '%s/%s.json\n' "$DOH_STATE_HOME" "$1"
}

read_state() {
  local profile=$1
  local expression=$2
  local file

  file=$(state_file "$profile")
  [[ -f "$file" ]] || die "no local $profile Droplet state; run: doh $profile up"
  jq -er "$expression" "$file"
}

write_state() {
  local profile=$1
  local id=$2
  local name=$3
  local ip=$4
  local size=$5
  local file temporary

  ensure_private_directory "$DOH_STATE_HOME"
  file=$(state_file "$profile")
  temporary=$(mktemp "$DOH_STATE_HOME/.$profile.json.XXXXXX")
  TEMP_FILES+=("$temporary")

  jq -n \
    --arg profile "$profile" \
    --arg id "$id" \
    --arg name "$name" \
    --arg ip "$ip" \
    --arg size "$size" \
    --arg region "$REGION" \
    --arg ssh_user "$SSH_USER" \
    --arg created_at "$(date --iso-8601=seconds)" \
    '{
      profile: $profile,
      id: ($id | tonumber),
      name: $name,
      ip: $ip,
      size: $size,
      region: $region,
      ssh_user: $ssh_user,
      public_ports: [],
      ports_firewall_id: "",
      created_at: $created_at
    }' >"$temporary"

  chmod 0600 "$temporary"
  mv -- "$temporary" "$file"
}

ssh_key_json() {
  local json

  json=$(doctl_context compute ssh-key get "$SSH_KEY" --output json)
  check_api_json "$json" "retrieving SSH key $SSH_KEY"
  printf '%s\n' "$json"
}

ssh_public_key() {
  ssh_key_json | jq -er 'if type == "array" then .[0] else . end | .public_key | strings | select(length > 0)'
}

ensure_tag() {
  local tag=$1

  if ! doctl_context compute tag get "$tag" >/dev/null 2>&1; then
    doctl_context compute tag create "$tag" >/dev/null
  fi
}

firewall_id_for_profile() {
  local profile=$1
  local firewall_name="doh-$profile"
  local firewalls_json

  firewalls_json=$(doctl_context compute firewall list --output json)
  check_api_json "$firewalls_json" "listing cloud firewalls"
  jq -r --arg name "$firewall_name" \
    '[.[] | select(.name == $name) | .id] | first // empty' \
    <<<"$firewalls_json"
}

ensure_firewall() {
  local profile=$1
  local role_tag="doh-$profile"
  local firewall_name="doh-$profile"
  local inbound_rules
  local outbound_rules
  local firewall_id

  if [[ "$profile" == "router" ]]; then
    inbound_rules="protocol:tcp,ports:22,address:$SSH_CIDR protocol:udp,ports:$WG_PORT,address:0.0.0.0/0"
  else
    inbound_rules="protocol:tcp,ports:22,address:$SSH_CIDR"
  fi

  outbound_rules="protocol:icmp,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:all,address:0.0.0.0/0,address:::/0 protocol:udp,ports:all,address:0.0.0.0/0,address:::/0"

  ensure_tag "$DOH_MANAGED_TAG"
  ensure_tag "$role_tag"

  firewall_id=$(firewall_id_for_profile "$profile")

  if [[ -z "$firewall_id" ]]; then
    printf 'Creating DigitalOcean cloud firewall %s...\n' "$firewall_name"
    doctl_context compute firewall create \
      --name "$firewall_name" \
      --tag-names "$role_tag" \
      --inbound-rules "$inbound_rules" \
      --outbound-rules "$outbound_rules" \
      >/dev/null
  else
    printf 'Updating DigitalOcean cloud firewall %s...\n' "$firewall_name"
    doctl_context compute firewall update "$firewall_id" \
      --name "$firewall_name" \
      --tag-names "$role_tag" \
      --inbound-rules "$inbound_rules" \
      --outbound-rules "$outbound_rules" \
      >/dev/null
  fi
}

validate_port_specification() {
  local specification=$1
  local first last

  if [[ "$specification" =~ ^[0-9]+$ ]]; then
    first=$specification
    last=$specification
  elif [[ "$specification" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    first=${BASH_REMATCH[1]}
    last=${BASH_REMATCH[2]}
  else
    die "$specification is not a port or port range"
  fi

  first=$((10#$first))
  last=$((10#$last))
  (( first >= 1 && first <= 65535 )) || die "port $first is outside 1-65535"
  (( last >= 1 && last <= 65535 )) || die "port $last is outside 1-65535"
  (( first <= last )) || die "port range must be ordered from lowest to highest"
}

validate_source_cidr() {
  local source=$1
  local prefix

  [[ "$source" =~ ^[0-9a-fA-F:.]+/([0-9]{1,3})$ ]] || die "$source is not a CIDR"
  prefix=${BASH_REMATCH[1]}
  prefix=$((10#$prefix))

  if [[ "$source" == *:* ]]; then
    (( prefix <= 128 )) || die "IPv6 CIDR prefix must be between 0 and 128"
  else
    (( prefix <= 32 )) || die "IPv4 CIDR prefix must be between 0 and 32"
  fi
}

parse_port_rule_arguments() {
  [[ $# -ge 1 ]] || die "a port or port range is required"

  PORT_SPECIFICATION=$1
  PORT_PROTOCOL="tcp"
  PORT_SOURCE="0.0.0.0/0"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --protocol)
        [[ $# -ge 2 && -n $2 ]] || die "--protocol requires tcp or udp"
        PORT_PROTOCOL=$2
        shift 2
        ;;
      --source)
        [[ $# -ge 2 && -n $2 ]] || die "--source requires a CIDR"
        PORT_SOURCE=$2
        shift 2
        ;;
      *)
        die "unknown port rule option: $1"
        ;;
    esac
  done

  validate_port_specification "$PORT_SPECIFICATION"
  [[ "$PORT_PROTOCOL" == "tcp" || "$PORT_PROTOCOL" == "udp" ]] \
    || die "protocol must be tcp or udp"
  validate_source_cidr "$PORT_SOURCE"
}

update_dev_port_state() {
  local operation=$1
  local firewall_id=$2
  local file temporary

  file=$(state_file dev)
  temporary=$(mktemp "$DOH_STATE_HOME/.dev.json.XXXXXX")
  TEMP_FILES+=("$temporary")

  if [[ "$operation" == "add" ]]; then
    jq \
      --arg ports "$PORT_SPECIFICATION" \
      --arg protocol "$PORT_PROTOCOL" \
      --arg source "$PORT_SOURCE" \
      --arg firewall_id "$firewall_id" \
      '.public_ports = (((.public_ports // []) + [{ports: $ports, protocol: $protocol, source: $source}]) | unique_by([.ports, .protocol, .source]))
       | .ports_firewall_id = $firewall_id' \
      "$file" >"$temporary"
  else
    jq \
      --arg ports "$PORT_SPECIFICATION" \
      --arg protocol "$PORT_PROTOCOL" \
      --arg source "$PORT_SOURCE" \
      --arg firewall_id "$firewall_id" \
      '.public_ports = ((.public_ports // []) | map(select((.ports == $ports and .protocol == $protocol and .source == $source) | not)))
       | .ports_firewall_id = $firewall_id' \
      "$file" >"$temporary"
  fi

  chmod 0600 "$temporary"
  mv -- "$temporary" "$file"
}

manage_dev_port() {
  local operation=$1
  shift
  local file firewall_id rule already_recorded droplet_id rule_count
  local create_json firewall_name

  file=$(state_file dev)
  [[ -f "$file" ]] || die "no active dev Droplet state; run: doh dev up"
  parse_port_rule_arguments "$@"

  already_recorded=$(jq -r \
    --arg ports "$PORT_SPECIFICATION" \
    --arg protocol "$PORT_PROTOCOL" \
    --arg source "$PORT_SOURCE" \
    'any((.public_ports // [])[]; .ports == $ports and .protocol == $protocol and .source == $source)' \
    "$file")

  if [[ "$operation" == "open" && "$already_recorded" == "true" ]]; then
    printf '%s/%s from %s is already open.\n' "$PORT_SPECIFICATION" "$PORT_PROTOCOL" "$PORT_SOURCE"
    return
  fi
  if [[ "$operation" == "close" && "$already_recorded" != "true" ]]; then
    die "$PORT_SPECIFICATION/$PORT_PROTOCOL from $PORT_SOURCE is not recorded as open; inspect: doh dev ports"
  fi

  firewall_id=$(jq -r '.ports_firewall_id // empty' "$file")
  droplet_id=$(jq -er '.id' "$file")
  rule="protocol:$PORT_PROTOCOL,ports:$PORT_SPECIFICATION,address:$PORT_SOURCE"

  if [[ "$operation" == "open" ]]; then
    if [[ -z "$firewall_id" ]]; then
      firewall_name="doh-dev-ports-$droplet_id"
      create_json=$(doctl_context compute firewall create \
        --name "$firewall_name" \
        --droplet-ids "$droplet_id" \
        --inbound-rules "$rule" \
        --output json)
      check_api_json "$create_json" "creating $firewall_name"
      firewall_id=$(jq -er 'if type == "array" then .[0].id else .id end' <<<"$create_json") \
        || die "created $firewall_name but could not read its ID"
    else
      doctl_context compute firewall add-rules "$firewall_id" --inbound-rules "$rule"
    fi
    update_dev_port_state add "$firewall_id"
    printf 'Opened %s/%s from %s on the dev Droplet.\n' \
      "$PORT_SPECIFICATION" "$PORT_PROTOCOL" "$PORT_SOURCE"
  else
    [[ -n "$firewall_id" ]] || die "local port state has no associated DigitalOcean firewall"
    rule_count=$(jq '(.public_ports // []) | length' "$file")
    if (( rule_count == 1 )); then
      doctl_context compute firewall delete "$firewall_id" --force
      firewall_id=""
    else
      doctl_context compute firewall remove-rules "$firewall_id" --inbound-rules "$rule"
    fi
    update_dev_port_state remove "$firewall_id"
    printf 'Closed %s/%s from %s on the dev Droplet.\n' \
      "$PORT_SPECIFICATION" "$PORT_PROTOCOL" "$PORT_SOURCE"
  fi
}

show_dev_ports() {
  local file count

  file=$(state_file dev)
  [[ -f "$file" ]] || die "no active dev Droplet state; run: doh dev up"
  count=$(jq '(.public_ports // []) | length' "$file")

  if (( count == 0 )); then
    printf 'No additional public ports are open. SSH remains allowed by the baseline firewall.\n'
    return
  fi

  {
    printf 'PORTS\tPROTOCOL\tSOURCE\n'
    jq -r '(.public_ports // [])[] | [.ports, .protocol, .source] | @tsv' "$file"
  } | column -t -s $'\t'
}

available_sizes_json() {
  local json

  json=$(doctl_context compute size list --output json)
  check_api_json "$json" "listing Droplet sizes"
  jq --arg region "$REGION" '[.[] | select(.available == true and ((.regions // []) | index($region)) != null)]' \
    <<<"$json"
}

resolve_size() {
  local profile=$1
  local sizes_json=$2
  local selected

  if [[ "$PROFILE_SIZE" != "auto" ]]; then
    selected=$PROFILE_SIZE
  elif [[ "$profile" == "router" ]]; then
    selected=$(jq -er '
      [.[] | select(.slug | startswith("s-"))]
      | sort_by(.price_monthly, .memory, .vcpus)
      | first
      | .slug
    ' <<<"$sizes_json")
  else
    selected=$(jq -er --argjson maximum "$PROFILE_MAX_PRICE" '
      [.[] | select((.slug | startswith("s-")) and .price_monthly <= $maximum)]
      | sort_by(.price_monthly, .memory, .vcpus)
      | last
      | .slug
    ' <<<"$sizes_json")
  fi

  printf '%s\n' "$selected"
}

check_size_and_price() {
  local size=$1
  local sizes_json=$2
  local details price

  details=$(jq -er --arg slug "$size" '.[] | select(.slug == $slug)' <<<"$sizes_json") \
    || die "size $size is not currently available in $REGION"
  price=$(jq -er '.price_monthly' <<<"$details")

  if jq -n -e --argjson price "$price" --argjson maximum "$PROFILE_MAX_PRICE" '$price > $maximum' >/dev/null; then
    die "size $size currently costs \$$price/month, above the configured \$$PROFILE_MAX_PRICE limit"
  fi

  printf 'Selected %s: %s MiB RAM, %s vCPU, $%s/month ($%s/hour).\n' \
    "$size" \
    "$(jq -r '.memory' <<<"$details")" \
    "$(jq -r '.vcpus' <<<"$details")" \
    "$price" \
    "$(jq -r '.price_hourly' <<<"$details")"
}

sed_replacement() {
  # sed is clearer here because three different characters need escaping.
  # shellcheck disable=SC2001
  sed 's/[&|\\]/\\&/g' <<<"$1"
}

render_cloud_init() {
  local profile=$1
  local public_key=$2
  local source_file temporary
  local escaped_user escaped_key escaped_client_key

  if [[ "$profile" == "router" ]]; then
    source_file=$DOH_ROUTER_CLOUD_INIT
  else
    source_file=$DOH_DEV_CLOUD_INIT
  fi

  temporary=$(mktemp "${TMPDIR:-/tmp}/doh-cloud-init.XXXXXX")
  TEMP_FILES+=("$temporary")
  cp -- "$source_file" "$temporary"

  escaped_user=$(sed_replacement "$SSH_USER")
  escaped_key=$(sed_replacement "$public_key")
  sed -i \
    -e "s|__DOH_USER__|$escaped_user|g" \
    -e "s|__DOH_SSH_PUBLIC_KEY__|$escaped_key|g" \
    "$temporary"

  if [[ "$profile" == "router" ]]; then
    local client_public_key
    client_public_key=$(ensure_wireguard_client_key)
    escaped_client_key=$(sed_replacement "$client_public_key")
    sed -i \
      -e "s|__DOH_WG_PORT__|$WG_PORT|g" \
      -e "s|__DOH_CLIENT_PUBLIC_KEY__|$escaped_client_key|g" \
      "$temporary"
  fi

  printf '%s\n' "$temporary"
}

ensure_wireguard_client_key() {
  local directory="$DOH_STATE_HOME/wireguard"
  local private_key="$directory/client.key"
  local public_key="$directory/client.pub"

  ensure_private_directory "$DOH_STATE_HOME"
  ensure_private_directory "$directory"

  if [[ ! -s "$private_key" ]]; then
    umask 077
    wg genkey >"$private_key"
    chmod 0600 "$private_key"
  fi

  wg pubkey <"$private_key" >"$public_key"
  chmod 0600 "$public_key"
  tr -d '\n' <"$public_key"
}

wireguard_config_file() {
  printf '%s/wireguard/%s.conf\n' "$DOH_STATE_HOME" "$DOH_WG_INTERFACE"
}

write_wireguard_config() {
  local endpoint_ip=$1
  local server_public_key=$2
  local directory="$DOH_STATE_HOME/wireguard"
  local private_key="$directory/client.key"
  local config temporary

  config=$(wireguard_config_file)
  temporary=$(mktemp "$directory/.wireguard.conf.XXXXXX")
  TEMP_FILES+=("$temporary")

  {
    printf '[Interface]\n'
    printf 'PrivateKey = %s\n' "$(<"$private_key")"
    printf 'Address = 10.77.0.2/32\n\n'
    printf '[Peer]\n'
    printf 'PublicKey = %s\n' "$server_public_key"
    printf 'Endpoint = %s:%s\n' "$endpoint_ip" "$WG_PORT"
    printf 'AllowedIPs = 0.0.0.0/0\n'
    printf 'PersistentKeepalive = 25\n'
  } >"$temporary"

  chmod 0600 "$temporary"
  mv -- "$temporary" "$config"
}

droplet_json() {
  local id=$1
  local json

  json=$(doctl_context compute droplet get "$id" --output json)
  check_api_json "$json" "retrieving Droplet $id"
  jq -e 'if type == "array" then .[0] else . end' <<<"$json"
}

droplet_ip_from_api() {
  local id=$1

  droplet_json "$id" \
    | jq -er '[.networks.v4[]? | select(.type == "public") | .ip_address] | first'
}

wait_for_public_ip() {
  local id=$1
  local ip=""
  local attempt

  for attempt in $(seq 1 60); do
    ip=$(droplet_ip_from_api "$id" 2>/dev/null || true)
    if [[ -n "$ip" ]]; then
      printf '%s\n' "$ip"
      return
    fi
    sleep 2
  done

  die "Droplet $id was created but no public IPv4 address appeared"
}

ssh_target() {
  local profile=$1
  local ip user

  ip=$(read_state "$profile" '.ip | strings | select(length > 0)')
  user=$(read_state "$profile" '.ssh_user | strings | select(length > 0)')
  printf '%s@%s\n' "$user" "$ip"
}

ssh_to_profile() {
  local profile=$1
  shift

  ssh \
    -o ConnectTimeout=10 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    "$(ssh_target "$profile")" \
    "$@"
}

wait_for_ssh() {
  local profile=$1
  local attempt

  printf 'Waiting for SSH and first-boot provisioning'
  for attempt in $(seq 1 180); do
    if ssh \
      -o BatchMode=yes \
      -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=accept-new \
      "$(ssh_target "$profile")" \
      true \
      >/dev/null 2>&1; then
      printf '\n'
      return
    fi

    if (( attempt % 6 == 0 )); then
      printf '.'
    fi
    sleep 5
  done

  printf '\n'
  die "timed out waiting for SSH; inspect the Droplet console and /var/log/cloud-init-output.log"
}

wait_for_cloud_init() {
  local profile=$1

  printf 'Waiting for cloud-init to finish...\n'
  if ! ssh_to_profile "$profile" sudo cloud-init status --wait; then
    warn "cloud-init did not complete successfully"
    warn "inspect it with: doh $profile ssh sudo tail -n 200 /var/log/cloud-init-output.log"
    return 1
  fi
}

create_droplet() {
  local profile=$1
  local connect_after=${2:-false}
  local existing_state role_tag name sizes_json size public_key cloud_init
  local create_json id ip project_arguments=()

  existing_state=$(state_file "$profile")
  [[ ! -e "$existing_state" ]] || die "$profile already has local state; inspect it with: doh $profile status"

  load_profile "$profile"
  public_key=$(ssh_public_key) || die "could not retrieve ssh_key $SSH_KEY from DigitalOcean"
  sizes_json=$(available_sizes_json)
  size=$(resolve_size "$profile" "$sizes_json")
  check_size_and_price "$size" "$sizes_json"
  ensure_firewall "$profile"

  cloud_init=$(render_cloud_init "$profile" "$public_key")
  role_tag="doh-$profile"
  name=$DROPLET_NAME

  if [[ -n "$PROJECT_ID" ]]; then
    project_arguments=(--project-id "$PROJECT_ID")
  fi

  printf 'Creating %s in %s...\n' "$name" "$REGION"
  create_json=$(doctl_context compute droplet create "$name" \
    --region "$REGION" \
    --size "$size" \
    --image "$IMAGE" \
    --ssh-keys "$SSH_KEY" \
    --tag-names "$DOH_MANAGED_TAG,$role_tag" \
    --user-data-file "$cloud_init" \
    --enable-private-networking \
    --wait \
    --wait-timeout 600 \
    --output json \
    "${project_arguments[@]}")
  check_api_json "$create_json" "creating $name"

  id=$(jq -er 'if type == "array" then .[0].id else .id end' <<<"$create_json") \
    || die "DigitalOcean created $name, but doh could not read its ID; recover it with: doh list"

  write_state "$profile" "$id" "$name" "" "$size"
  ip=$(wait_for_public_ip "$id")
  write_state "$profile" "$id" "$name" "$ip" "$size"

  ssh-keygen -R "$ip" >/dev/null 2>&1 || true
  printf 'Created %s (%s) at %s.\n' "$name" "$id" "$ip"

  wait_for_ssh "$profile"
  wait_for_cloud_init "$profile"

  if [[ "$profile" == "router" ]]; then
    local server_public_key
    server_public_key=$(ssh_to_profile router sudo cat /etc/wireguard/server.pub | tr -d '\r\n')
    [[ -n "$server_public_key" ]] || die "router did not expose its WireGuard public key"
    write_wireguard_config "$ip" "$server_public_key"
    printf 'WireGuard client configuration written to %s.\n' "$(wireguard_config_file)"

    if [[ "$connect_after" == "true" ]]; then
      connect_router
    else
      printf 'Connect with: doh router connect\n'
    fi
  else
    printf 'SSH with:          doh dev ssh\n'
    printf 'Herdr TUI:         herdr --remote %s\n' "$(ssh_target dev)"
    printf 'Herdr Core setup:  hc machine add %s --name doh-dev\n' "$(ssh_target dev)"
  fi
}

connect_router() {
  local config wg_quick

  config=$(wireguard_config_file)
  [[ -f "$config" ]] || die "missing WireGuard client configuration; run: doh router up"

  if ip link show "$DOH_WG_INTERFACE" >/dev/null 2>&1; then
    printf 'WireGuard router is already connected.\n'
    return
  fi

  wg_quick=$(command -v wg-quick)
  sudo "$wg_quick" up "$config"
  printf 'All IPv4 traffic is now routed through the Droplet. IPv6 is not routed.\n'
}

disconnect_router() {
  local config wg_quick

  config=$(wireguard_config_file)
  if ! ip link show "$DOH_WG_INTERFACE" >/dev/null 2>&1; then
    printf 'WireGuard router is not connected.\n'
    return
  fi

  [[ -f "$config" ]] || die "WireGuard interface exists but $config is missing"
  wg_quick=$(command -v wg-quick)
  sudo "$wg_quick" down "$config"
  printf 'WireGuard router disconnected.\n'
}

confirm_destructive_action() {
  local prompt=$1
  local assume_yes=$2
  local response

  if [[ "$assume_yes" == "true" ]]; then
    return
  fi

  [[ -t 0 ]] || die "refusing destructive action without a terminal; pass --yes to confirm"
  read -r -p "$prompt [y/N] " response
  [[ "$response" == "y" || "$response" == "Y" ]] || die "cancelled"
}

destroy_droplet() {
  local profile=$1
  local assume_yes=${2:-false}
  local file id expected_name ip json actual_name tags

  file=$(state_file "$profile")
  [[ -f "$file" ]] || die "no local $profile Droplet state"
  id=$(read_state "$profile" '.id')
  expected_name=$(read_state "$profile" '.name')
  ip=$(read_state "$profile" '.ip')

  json=$(droplet_json "$id") || die "could not retrieve Droplet $id; if it was deleted elsewhere, use: doh $profile forget"
  actual_name=$(jq -er '.name' <<<"$json")
  tags=$(jq -c '.tags // []' <<<"$json")

  [[ "$actual_name" == "$expected_name" ]] || die "Droplet $id is now named $actual_name, expected $expected_name; refusing deletion"
  jq -e --arg tag "$DOH_MANAGED_TAG" 'index($tag) != null' <<<"$tags" >/dev/null \
    || die "Droplet $id no longer has the $DOH_MANAGED_TAG tag; refusing deletion"
  jq -e --arg tag "doh-$profile" 'index($tag) != null' <<<"$tags" >/dev/null \
    || die "Droplet $id no longer has the doh-$profile tag; refusing deletion"

  confirm_destructive_action \
    "Permanently destroy $actual_name ($id, $ip)? Make sure all work is pushed." \
    "$assume_yes"

  if [[ "$profile" == "router" ]] && ip link show "$DOH_WG_INTERFACE" >/dev/null 2>&1; then
    disconnect_router
  fi

  if [[ "$profile" == "dev" ]]; then
    local ports_firewall_id
    ports_firewall_id=$(jq -r '.ports_firewall_id // empty' "$file")
    if [[ -n "$ports_firewall_id" ]]; then
      printf 'Deleting the Droplet-specific public-ports firewall...\n'
      doctl_context compute firewall delete "$ports_firewall_id" --force
    fi
  fi

  doctl_context compute droplet delete "$id" --force
  rm -f -- "$file"
  ssh-keygen -R "$ip" >/dev/null 2>&1 || true
  printf 'Destroyed %s. DigitalOcean billing for that Droplet has stopped.\n' "$actual_name"
}

forget_state() {
  local profile=$1
  local assume_yes=${2:-false}
  local file ip=""

  file=$(state_file "$profile")
  [[ -f "$file" ]] || die "no local $profile Droplet state"
  ip=$(jq -r '.ip // empty' "$file")

  confirm_destructive_action \
    "Forget local $profile state? This does not destroy anything at DigitalOcean." \
    "$assume_yes"

  if [[ "$profile" == "router" ]] && ip link show "$DOH_WG_INTERFACE" >/dev/null 2>&1; then
    disconnect_router
  fi

  if [[ "$profile" == "dev" ]]; then
    local ports_firewall_id
    ports_firewall_id=$(jq -r '.ports_firewall_id // empty' "$file")
    if [[ -n "$ports_firewall_id" ]]; then
      warn "forgetting state does not delete public-ports firewall $ports_firewall_id"
    fi
  fi

  rm -f -- "$file"
  if [[ -n "$ip" ]]; then
    ssh-keygen -R "$ip" >/dev/null 2>&1 || true
  fi
  printf 'Forgot local %s state.\n' "$profile"
}

show_status() {
  local profile=$1
  local file id json

  file=$(state_file "$profile")
  if [[ ! -f "$file" ]]; then
    printf '%s: no local Droplet state\n' "$profile"
    return
  fi

  id=$(read_state "$profile" '.id')
  printf 'Local state:\n'
  jq . "$file"

  if json=$(droplet_json "$id" 2>/dev/null); then
    printf '\nDigitalOcean:\n'
    jq '{id, name, status, region: .region.slug, size: .size_slug, ip: ([.networks.v4[]? | select(.type == "public") | .ip_address] | first), tags}' <<<"$json"
  else
    warn "Droplet $id is not available through the API; local state may be stale"
  fi

  if [[ "$profile" == "router" ]]; then
    if ip link show "$DOH_WG_INTERFACE" >/dev/null 2>&1; then
      printf '\nWireGuard: connected\n'
      sudo "$(command -v wg)" show "$DOH_WG_INTERFACE"
    else
      printf '\nWireGuard: disconnected\n'
    fi
  fi
}

show_sizes() {
  local sizes_json

  sizes_json=$(available_sizes_json)
  {
    printf 'SLUG\tRAM_MIB\tVCPUS\tDISK_GIB\tMONTHLY\tHOURLY\n'
    jq -r '
      sort_by(.price_monthly, .memory, .vcpus)[]
      | [.slug, .memory, .vcpus, .disk, .price_monthly, .price_hourly]
      | @tsv
    ' <<<"$sizes_json"
  } | column -t -s $'\t'
}

doctor() {
  local profile sizes_json size

  printf 'Configuration: %s\n' "$DOH_CONFIG_FILE"
  printf 'Region:        %s\n' "$REGION"
  printf 'Image:         %s\n' "$IMAGE"
  printf 'SSH user:      %s\n' "$SSH_USER"
  printf 'SSH CIDR:      %s\n' "$SSH_CIDR"

  ssh_public_key >/dev/null || die "cannot retrieve DigitalOcean SSH key $SSH_KEY"
  sizes_json=$(available_sizes_json)
  [[ $(jq 'length' <<<"$sizes_json") -gt 0 ]] || die "no sizes are available in $REGION"

  for profile in router dev; do
    load_profile "$profile"
    size=$(resolve_size "$profile" "$sizes_json")
    printf '\n%s profile:\n' "$profile"
    check_size_and_price "$size" "$sizes_json"
  done

  printf '\nConfiguration and DigitalOcean access look usable.\n'
}

parse_yes_flag() {
  if [[ $# -eq 0 ]]; then
    printf 'false\n'
  elif [[ $# -eq 1 && $1 == "--yes" ]]; then
    printf 'true\n'
  else
    die "only --yes is accepted here"
  fi
}

parse_region_flag() {
  if [[ $# -eq 0 ]]; then
    printf '\n'
  elif [[ $# -eq 2 && $1 == "--region" && -n $2 ]]; then
    printf '%s\n' "$2"
  else
    die "expected --region <slug>"
  fi
}

main() {
  local command=${1:-help}
  local profile action assume_yes connect_after
  local requested_region requested_name requested_user name_was_provided

  case "$command" in
    help | -h | --help)
      usage
      ;;
    init)
      [[ $# -eq 1 ]] || die "usage: doh init"
      init_config
      ;;
    doctor | sizes)
      shift
      load_config
      select_region "$(parse_region_flag "$@")"
      case "$command" in
        doctor) doctor ;;
        sizes) show_sizes ;;
      esac
      ;;
    keys | list)
      [[ $# -eq 1 ]] || die "usage: doh $command"
      load_config
      case "$command" in
        keys) doctl_context compute ssh-key list ;;
        list)
          doctl_context compute droplet list \
            --tag-name "$DOH_MANAGED_TAG" \
            --format ID,Name,PublicIPv4,Region,Status,Tags
          ;;
      esac
      ;;
    dev | router)
      profile=$command
      action=${2:-status}
      shift 2 || true
      load_config

      case "$action" in
        up)
          connect_after=false
          requested_region=""
          requested_name=""
          requested_user=""
          name_was_provided=false
          while [[ $# -gt 0 ]]; do
            case "$1" in
              --region)
                [[ $# -ge 2 && -n $2 ]] || die "--region requires a slug"
                requested_region=$2
                shift 2
                ;;
              --name)
                [[ $# -ge 2 && -n $2 ]] || die "--name requires a hostname"
                requested_name=$2
                name_was_provided=true
                shift 2
                ;;
              --user)
                [[ $# -ge 2 && -n $2 ]] || die "--user requires a Linux user name"
                requested_user=$2
                shift 2
                ;;
              --connect)
                [[ "$profile" == "router" ]] || die "--connect is only valid for the router profile"
                connect_after=true
                shift
                ;;
              *)
                die "unknown option for $profile up: $1"
                ;;
            esac
          done

          if [[ -n "$requested_user" ]]; then
            validate_ssh_user "$requested_user"
            SSH_USER=$requested_user
          fi

          select_droplet_name "$profile" "$requested_name" "$name_was_provided"
          select_region "$requested_region"
          create_droplet "$profile" "$connect_after"
          ;;
        ssh)
          ssh_to_profile "$profile" "$@"
          ;;
        ip)
          [[ $# -eq 0 ]] || die "usage: doh $profile ip"
          read_state "$profile" '.ip | strings | select(length > 0)'
          ;;
        status)
          [[ $# -eq 0 ]] || die "usage: doh $profile status"
          show_status "$profile"
          ;;
        open | close)
          [[ "$profile" == "dev" ]] || die "$action is only valid for the dev profile"
          manage_dev_port "$action" "$@"
          ;;
        ports)
          [[ "$profile" == "dev" ]] || die "ports is only valid for the dev profile"
          [[ $# -eq 0 ]] || die "usage: doh dev ports"
          show_dev_ports
          ;;
        down)
          assume_yes=$(parse_yes_flag "$@")
          destroy_droplet "$profile" "$assume_yes"
          ;;
        forget)
          assume_yes=$(parse_yes_flag "$@")
          forget_state "$profile" "$assume_yes"
          ;;
        connect)
          [[ "$profile" == "router" ]] || die "connect is only valid for the router profile"
          [[ $# -eq 0 ]] || die "usage: doh router connect"
          load_profile router
          connect_router
          ;;
        disconnect)
          [[ "$profile" == "router" ]] || die "disconnect is only valid for the router profile"
          [[ $# -eq 0 ]] || die "usage: doh router disconnect"
          load_profile router
          disconnect_router
          ;;
        *)
          die "unknown $profile action: $action"
          ;;
      esac
      ;;
    *)
      die "unknown command: $command; run: doh help"
      ;;
  esac
}

main "$@"
