
function mkd() {
  mkdir "$1" && cd "$_"
}

# reload shell
function reload() {
  omz reload
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
  local tmpFile="${@%/}.tar"
  tar -cvf "${tmpFile}" --exclude={".DS_Store","node_modules"} --exclude-vcs "${@}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
    stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
  )

  local cmd=""

  if hash pigz 2> /dev/null; then
    cmd="pigz"
  else
    cmd="gzip"
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
  echo "${tmpFile}.gz created successfully."
}

# Determine size of a file or total size of a directory
function fs() {
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
  else
    local arg=-sh
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@"
  else
    du $arg .[^.]* *
  fi
}

# Create a data URL from a file
function dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Show all the names (CNs and SANs) listed in the SSL certificate for a given domain
function getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  printf "Testing %s …\n\n" "${domain}"

  local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" 2>&1);

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_header, no_serial, no_version, \
      no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux");
      echo "Common Name:"
      echo # newline
      echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//";
      echo # newline
      echo "Subject Alternative Name(s):"
      echo # newline
      echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
        | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
      return 0
  else
    echo "ERROR: Certificate not found.";
    return 1
  fi
}

# Check weather using "weather Cityname"
function weather() {
    city="$1"

    if [ -z "$city" ]; then
        city="Berlin"
    fi

    curl "https://wttr.in/${city}"
}


# Show whats running on port X
function port() {
  ! [ $# -eq 1 ] && echo "Please define the port you want to check \n $ port 8000"; return 1

  lsof -nP -i TCP:"$1"
}

# Kill processes at a given port
function killport() {
  echo '🚨 Killing all processes on port' $1
  lsof -ti tcp:$1 | xargs -i kill {}
}

function myip() {
  local local_interface=$(ip route get 8.8.8.8 | awk -F"dev " 'NR==1{split($2,a," ");print a[1]}')
  local public_provider="opendns"

  local public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  [ -z "${public_ip}" ] && public_ip=$(dig +short txt ch whoami.cloudflare @1.1.1.1) && public_provider="cloudflare"
  [ -z "${public_ip}" ] && public_ip=$(dig +short txt o-o.myaddr.test.l.google.com @ns1.google.com) && public_provider="google"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://ifconfig.me) && public_provider="ifconfig.me"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://icanhazip.com) && public_provider="iconhazip.com"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://ipinfo.io/ip) && public_provider="ipinfo.io"
  printf "public IPv4 [%s]: \t%s\n" ${public_provider} ${public_ip}

  local local_ipv4=$(ip -4 route get 1.1.1.1 | sed -n 's/^.*src \([0-9.]*\).*$/\1/p')
  local local_ipv6=$(ip address show ${local_interface} | perl -nwe 'print /^\s+inet6\s+(.*?)\//;')
  local default_gateway=$(ip route show default | awk '/^default/ {print $3}')

  printf "local IPv4 [%s]: \t%s\n" ${local_interface} ${local_ipv4}
  [ -z "${local_ipv6}" ] && local_ipv6="n/a"
  printf "local IPv6 [%s]: \t%s\n" ${local_interface} ${local_ipv6}
  [ -z "${default_gateway}" ] && default_gateway="n/a"
  printf "Default Gateway: \t%s\n" ${default_gateway}
}

##### DOCKER

function get-docker-info(){
  [ -z "$(command -v docker)" ] && return 2;
  local ram_in_byte ram_in_gb
  ram_in_byte=$(docker system info -f '{{ .MemTotal }}')
  ram_in_gb=$(echo "$ram_in_byte" | awk '{ printf "%.2f", $1/1024/1024/1024; }')

  docker system info -f "============= Docker INFO =============
Docker Version: {{.ServerVersion}}
OS: {{.OSType}}
Architecture: {{.Architecture}}
Docker Kernel Version: {{.KernelVersion}}
Docker RAM: ${ram_in_gb}GB
Docker RootDir: {{.DockerRootDir}}
Images: {{.Images}}
Containers: {{.Containers}}
  Running: {{.ContainersRunning}}
  Stopped: {{.ContainersStopped}}
Plugins:
  {{range .ClientInfo.Plugins}}[{{.Name}}] {{.ShortDescription}} | {{.Version}}
  {{end}}"
}

function get-docker-gateway() {
  [ -z "$(command -v docker)" ] && return 2;
  docker network inspect bridge -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}'
}

# -a for all containers, otherwise only running ones
function get-docker-ips() {
  [ -z "$(command -v docker)" ] && return 0;

  local dockerFlags="-q"

  if [ ! -z "$1" ] && [ "$1" = "-a" ]; then
    dockerFlags="-aq"
  fi

  # networksettings can have mutliple networks, list only first
  docker ps "${dockerFlags}" | xargs -n 1 docker inspect --format '{{$ipCount := len .NetworkSettings.Networks}}{{ index (split .Name "/") 1}} {{range $i,$element := .NetworkSettings.Networks}}{{if .IPAddress}}[{{$i}}:{{.IPAddress}}]{{if (gt $ipCount 1) }} {{end}}{{end}}{{end}}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n
}

function get-docker-compose-ips() {
  [ -z "$(command -v docker)" ] && return 2;
  for N in $(docker compose ps -q) ; do
    echo "$(docker inspect -f '{{ index (split .Name "/") 1}}' ${N}) $(docker inspect -f '{{$ipCount := len .NetworkSettings.Networks}}{{range $i, $value := .NetworkSettings.Networks}}{{if .IPAddress}}[{{$i}}:{{.IPAddress}}]{{if (gt $ipCount 1) }} {{end}}{{end}}{{end}}' ${N})";
  done
}

function nvm-update-lts() {
  [ -z "$(command -v nvm)" ] && return 0;

  if [ "$(nvm current)" = "none" ]; then
    echo "No node versions currently installed. Installing fresh LTS."
    nvm install --lts --latest-npm

  else
    echo "Updating current node version to LTS: $(nvm current)"
    nvm install --lts --latest-npm --reinstall-packages-from="$(nvm current)"
    # nvm copy-packages "$(nvm current)"
    # nvm reinstall-packages "$(nvm current)"
  fi

  nvm use --lts
  nvm alias default "$(nvm current)"
}

function nvm-remove-all() {
  [ -z "$(command -v nvm)" ] && return 0;

  # 1. Deactivate to ensure the current version isn't locked
  nvm deactivate

  for version in $(nvm ls --no-alias | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' ); do
    nvm uninstall "${version}"
  done
}

# $1 = host
function checkssl() {
  local host=${1:-}

  if [ -z "$host" ]; then
    echo "❌ Error: Please provide a host (e.g., example.com)."
    return 1
  fi

  # DNS & Network Connectivity / Handshake
  # We fetch the HTTP headers here to capture the remote server's timestamp
  local headers curl_status
  headers=$(curl --fail --max-time 5 -sI "https://$host" 2>&1)
  curl_status=$?

  if [ $curl_status -ne 0 ]; then
    case $curl_status in
      6)
        echo "❌ Error: Domain '$host' does not exist or cannot be resolved (DNS failure)."
        ;;
      28)
        echo "❌ Error: Connection to $host:443 timed out."
        ;;
      7)
        echo "❌ Error: Connection refused by $host. Port 443 might be closed."
        ;;
      60|51)
        echo "❌ Error: SSL Certificate for '$host' is INVALID or EXPIRED."
        # Don't exit yet, let's still parse the dates if possible
        ;;
      *)
        echo "❌ Error: Connection failed ($headers)."
        ;;
    esac
    
    if [ $curl_status -ne 60 ] && [ $curl_status -ne 51 ]; then
      return 1
    fi
  fi

  # --- Extract Host Server's Timezone ---
  # Parse the "Date:" header from the server response (e.g., "Date: Fri, 03 Jul 2026 13:28:05 GMT")
  local server_date_header remote_tz="UTC"
  server_date_header=$(echo "$headers" | grep -i "^date:" | sed 's/\r//g')
  
  if [ -n "$server_date_header" ]; then
    # Extract the timezone string at the end of the HTTP date header (usually GMT or UTC)
    remote_tz=$(echo "$server_date_header" | awk '{print $G}' | awk '{print $NF}')
  fi

  # --- Extract Certificate Dates via OpenSSL ---
  local cert_output
  cert_output=$(echo | timeout 5 openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null)

  if ! echo "$cert_output" | grep -q "BEGIN CERTIFICATE"; then
    echo "❌ Error: Could not extract certificate details."
    return 1
  fi

  local raw_from raw_to
  raw_from=$(echo "$cert_output" | openssl x509 -noout -startdate | cut -d= -f2)
  raw_to=$(echo "$cert_output" | openssl x509 -noout -enddate | cut -d= -f2)

  # --- Date Formatting & Conversion ---
  # We set the TZ environment variable dynamically for the execution of the 'date' command
  local formatted_from formatted_to
  formatted_from=$(TZ="$remote_tz" date -d "$raw_from" +"Week %W - %a, %d %b %Y %H:%M %Z")
  formatted_to=$(TZ="$remote_tz" date -d "$raw_to" +"Week %W - %a, %d %b %Y %H:%M %Z")

  # Final Output
  if [ $curl_status -eq 0 ]; then
    echo "✅ SSL Certificate for '$host' is VALID."
    echo "   Valid From : $formatted_from ($remote_tz)"
    echo "   Expires On : $formatted_to ($remote_tz)"
    return 0
  else
    echo "   Expired On : $formatted_to ($remote_tz)"
    return 1
  fi
}


