
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
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

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

    eval "curl http://wttr.in/${city}"
}


# Show whats running on port X
function port() {
  ! [ $# -eq 1 ] && echo "Please define the port you want to check \n $ port 8000"; return 1

  lsof -nP -i TCP:"$1"
}

# Kill processes at a given port
function killport() {
  echo '🚨 Killing all processes on port' $1
  lsof -ti tcp:$1 | xargs kill
}

function myip() {
  local local_interface=$(ip route get 8.8.8.8 | awk -F"dev " 'NR==1{split($2,a," ");print a[1]}')
  local public_provider="opendns"

  local public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  [ -z "${public_ip}" ] && public_ip=$(dig +short txt ch whoami.cloudflare @1.1.1.1) && public_provider="cloudflare"
  [ -z "${public_ip}" ] && public_ip=$(dig +short txt o-o.myaddr.test.l.google.com @ns1.google.com) && public_provider="goggle"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://ifconfig.me) && public_provider="ifconfig.me"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://icanhazip.com) && public_provider="iconhazip.com"
  [ -z "${public_ip}" ] && public_ip=$(curl -s https://ipinfo.io/ip) && public_provider="ipinfo.io"
  printf "public IPv4 [%s]: \t%s\n" ${public_provider} ${public_ip}

  local local_ipv4=$(ip -4 route get 1.1.1.1 | sed -n 's/^.*src \([0-9.]*\).*$/\1/p')
  local local_ipv6=$(ip address show ${local_interface} | perl -nwe 'print /^\s+inet6\s+(.*?)\//;')
  local windows_wsl_ip=$(ip route | awk '/^default/ {print $3}')

  printf "local IPv4 [%s]: \t%s\n" ${local_interface} ${local_ipv4}
  [ -z "${local_ipv6}" ] && local_ipv6="n/a"
  printf "local IPv6 [%s]: \t%s\n" ${local_interface} ${local_ipv6}
  [ -z "${windows_wsl_ip}" ] && windows_wsl_ip="n/a"
  printf "Windows WSL: \t\t%s\n" ${windows_wsl_ip}
}

##### DOCKER

function get-docker-info(){
  [ -z "$(command -v docker)" ] && exit;
  docker system info -f '============= Docker News =============
Images: {{.Images}}
Containers: {{.Containers}}
  Running: {{.ContainersRunning}}
  Stopped: {{.ContainersStopped}}
OS: {{.OSType}}
Architecture: {{.Architecture}}
Docker Kernel Version: {{.KernelVersion}}
Docker Version: {{.ServerVersion}}
Docker RAM: {{ .MemTotal }}
Plugins:
  {{range .ClientInfo.Plugins}}[{{.Name}}] {{.ShortDescription}} | {{.Version}}
  {{end}}'
}

function get-docker-gateway() {
  [ -z "$(command -v docker)" ] && exit;
  docker network inspect bridge -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}'
}

function get-docker-ips() {
  [ -z "$(command -v docker)" ] && exit;

  docker ps -aq | xargs -n 1 docker inspect --format '{{$ipCount := len .NetworkSettings.Networks}}{{ index (split .Name "/") 1}} {{range $i,$element := .NetworkSettings.Networks}}{{if .IPAddress}}[{{$i}}:{{.IPAddress}}]{{if (gt $ipCount 1) }} {{end}}{{end}}{{end}}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n
}

function get-docker-compose-ips() {
  [ -z "$(command -v docker)" ] && exit;
  for N in $(docker compose ps -q) ; do
    echo "$(docker inspect -f '{{ index (split .Name "/") 1}}' ${N}) $(docker inspect -f '{{$ipCount := len .NetworkSettings.Networks}}{{range $i, $value := .NetworkSettings.Networks}}{{if .IPAddress}}[{{$i}}:{{.IPAddress}}]{{if (gt $ipCount 1) }} {{end}}{{end}}{{end}}' ${N})";
  done
}