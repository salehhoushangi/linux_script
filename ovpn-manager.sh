#!/usr/bin/env bash
set -euo pipefail
# ==========================================================
# OpenVPN Manager Script
# Written by: Saleh Houshangi
# Usage Examples:
#
# 1) Install & set up the server (TCP/4443) with auto-firewall/NAT:
#    sudo SERVER_IP=187.211.122.111 ./ovpn-manager.sh install
#
# 2) Create a new client and get an Android-ready .ovpn:
#    sudo ./ovpn-manager.sh add-user nikan-phone
#    # -> /root/clients/nikan-phone.ovpn (import into OpenVPN on Android)
#
# 3) Revoke (delete) a user:
#    sudo ./ovpn-manager.sh del-user salehho
#
# 4) Rebuild an .ovpn file if you lose it:
#    sudo ./ovpn-manager.sh make-ovpn salehho
#
# 5) Use different port/protocol:
#    sudo SERVER_IP=187.211.122.111 OVPN_PORT=1194 OVPN_PROTO=udp ./ovpn-manager.sh install
#
# Tip: If you want to store client files in /etc/openvpn/clients instead of /root/clients,
#      change CLIENT_OUTPUT_DIR in the script or override with:
#      sudo CLIENT_OUTPUT_DIR=/etc/openvpn/clients ./ovpn-manager.sh add-user test
#
# Need tweaks for your distro/firewall layout or split CA/server setup? Adapt as needed.
# ==========================================================
# === Config (defaults) ===
OVPN_PORT="${OVPN_PORT:-4443}"
OVPN_PROTO="${OVPN_PROTO:-tcp}"
OVPN_DEV="${OVPN_DEV:-tun}"
OVPN_NET="${OVPN_NET:-10.8.0.0}"
OVPN_MASK="${OVPN_MASK:-255.255.255.0}"
OVPN_DNS1="${OVPN_DNS1:-1.1.1.1}"
OVPN_DNS2="${OVPN_DNS2:-9.9.9.9}"
OVPN_SVC_NAME="server"
EASYRSA_DIR="/etc/easy-rsa"
OVPN_SERVER_DIR="/etc/openvpn/server"
CLIENT_OUTPUT_DIR="/etc/openvpn/clients"
CA_CN="${CA_CN:-OpenVPN-CA}"
SERVER_CN="${SERVER_CN:-server}"
# Optional: set SERVER_IP env or auto-detect
SERVER_IP="${SERVER_IP:-}"

# === Helpers ===
need_root() { [ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)."; exit 1; }; }

detect_server_ip() {
  if [ -n "${SERVER_IP}" ]; then
    echo "${SERVER_IP}"
    return
  fi
  # Try to detect default route interface IP
  if command -v ip >/dev/null 2>&1; then
    ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
  fi
}

ensure_dirs() {
  mkdir -p "${OVPN_SERVER_DIR}" "${CLIENT_OUTPUT_DIR}"
}

systemd_enable_start() {
  systemctl enable --now "openvpn-server@${OVPN_SVC_NAME}"
  systemctl status "openvpn-server@${OVPN_SVC_NAME}" --no-pager || true
}

configure_sysctl_forward() {
  echo 'net.ipv4.ip_forward=1' >/etc/sysctl.d/99-openvpn.conf
  sysctl --system
}

setup_firewall() {

 local cidr="${OVPN_NET:-10.8.0.0}/${OVPN_MASK:-255.255.255.0}"
  local IFACE
  IFACE=$(ip -4 route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')

  [ -n "$IFACE" ] || { echo "Could not detect outbound interface"; return 1; }

  # forwarding
  iptables -C FORWARD -s "$cidr" -o "$IFACE" -j ACCEPT 2>/dev/null || iptables -A FORWARD -s "$cidr" -o "$IFACE" -j ACCEPT
  iptables -C FORWARD -d "$cidr" -i "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -d "$cidr" -i "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT

  # NAT
  iptables -t nat -C POSTROUTING -s "$cidr" -o "$IFACE" -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s "$cidr" -o "$IFACE" -j MASQUERADE

  # persist
  command -v netfilter-persistent >/dev/null 2>&1 || apt-get install -y iptables-persistent >/dev/null 2>&1
  command -v netfilter-persistent >/dev/null 2>&1 && netfilter-persistent save || true

}


write_server_conf() {
  cat > "${OVPN_SERVER_DIR}/${OVPN_SVC_NAME}.conf" <<EOF
port ${OVPN_PORT}
proto ${OVPN_PROTO}
dev ${OVPN_DEV}

ca ${OVPN_SERVER_DIR}/ca.crt
cert ${OVPN_SERVER_DIR}/server.crt
key ${OVPN_SERVER_DIR}/server.key
dh ${OVPN_SERVER_DIR}/dh.pem

topology subnet
server ${OVPN_NET} ${OVPN_MASK}
ifconfig-pool-persist ${OVPN_SERVER_DIR}/ipp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS ${OVPN_DNS1}"
push "dhcp-option DNS ${OVPN_DNS2}"

keepalive 10 120
cipher AES-256-CBC
auth SHA256

# HMAC protection; pair with key-direction 1 on clients
tls-auth ${OVPN_SERVER_DIR}/ta.key 0
tls-version-min 1.2

persist-key
persist-tun
user nobody
group nogroup
verb 3

# CRL for revocations (created on first revoke)
crl-verify ${OVPN_SERVER_DIR}/crl.pem
EOF
}

install_openvpn() {
  need_root
  if [ -f "${OVPN_SERVER_DIR}/${OVPN_SVC_NAME}.conf" ] && [ -d "${EASYRSA_DIR}/pki" ]; then
    echo "OpenVPN server already installed and configured — skipping installation."
    return
  fi
  apt update
  apt install -y openvpn easy-rsa
  mkdir -p "${EASYRSA_DIR}"
  cp -r /usr/share/easy-rsa/* "${EASYRSA_DIR}/"
  cd "${EASYRSA_DIR}"

  export EASYRSA_BATCH=1
  export EASYRSA_REQ_CN="${CA_CN}"

  ./easyrsa init-pki
  ./easyrsa build-ca nopass

  export EASYRSA_REQ_CN="${SERVER_CN}"
  ./easyrsa gen-req "${SERVER_CN}" nopass
  ./easyrsa sign-req server "${SERVER_CN}"

  ./easyrsa gen-dh
  openvpn --genkey secret ta.key

  ensure_dirs
  cp pki/ca.crt pki/issued/${SERVER_CN}.crt pki/private/${SERVER_CN}.key pki/dh.pem ta.key "${OVPN_SERVER_DIR}/"
  ln -sf "${OVPN_SERVER_DIR}/${SERVER_CN}.crt" "${OVPN_SERVER_DIR}/server.crt"
  ln -sf "${OVPN_SERVER_DIR}/${SERVER_CN}.key" "${OVPN_SERVER_DIR}/server.key"

  write_server_conf
  configure_sysctl_forward
  setup_firewall
  systemd_enable_start

  echo "OpenVPN installed and started on ${OVPN_PROTO}/${OVPN_PORT}."
}

gen_client() {
  local name="$1"
  [ -n "${name}" ] || { echo "Client name required."; exit 1; }
  cd "${EASYRSA_DIR}"
  export EASYRSA_BATCH=1
  export EASYRSA_REQ_CN="${name}"
  ./easyrsa gen-req "${name}" nopass
  ./easyrsa sign-req client "${name}"
}

ensure_crl() {
  cd "${EASYRSA_DIR}"
  ./easyrsa gen-crl
  cp -f pki/crl.pem "${OVPN_SERVER_DIR}/crl.pem"
  chown nobody:nogroup "${OVPN_SERVER_DIR}/crl.pem" || true
  chmod 644 "${OVPN_SERVER_DIR}/crl.pem" || true
  systemctl restart "openvpn-server@${OVPN_SVC_NAME}"
}

revoke_client() {
  local name="$1"
  [ -n "${name}" ] || { echo "Client name required."; exit 1; }
  cd "${EASYRSA_DIR}"
  EASYRSA_BATCH=1 ./easyrsa revoke "${name}"
  ensure_crl
  echo "Client '${name}' revoked and CRL updated."
}

build_client_ovpn() {
  local name="$1"
  local server_ip
  server_ip=$(detect_server_ip)

  if [ -z "${server_ip}" ]; then
    echo "Could not detect server IP automatically. Set SERVER_IP env or pass it with OVPN creation."
    exit 1
  fi

  local ca crt key ta
  ca="$(cat "${EASYRSA_DIR}/pki/ca.crt")"
  crt="$(cat "${EASYRSA_DIR}/pki/issued/${name}.crt")"
  key="$(cat "${EASYRSA_DIR}/pki/private/${name}.key")"
  ta="$(cat "${OVPN_SERVER_DIR}/ta.key")"

  mkdir -p "${CLIENT_OUTPUT_DIR}"
  local outfile="${CLIENT_OUTPUT_DIR}/${name}.ovpn"
  cat > "${outfile}" <<EOF
client
dev ${OVPN_DEV}
proto ${OVPN_PROTO}
remote ${server_ip} ${OVPN_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA256
cipher AES-256-CBC
key-direction 1
verb 3

<ca>
${ca}
</ca>

<cert>
${crt}
</cert>

<key>
${key}
</key>

<tls-auth>
${ta}
</tls-auth>
EOF

  echo "Client profile written to: ${outfile}"
}

usage() {
  cat <<EOF
Usage:
  $0 install                       # Install OpenVPN + Easy-RSA and configure server
  $0 add-user   <name>             # Create client cert/key and Android-ready .ovpn
  $0 del-user   <name>             # Revoke client on the server
  $0 make-ovpn  <name>             # Rebuild .ovpn for existing client

Environment overrides (optional):
  SERVER_IP=1.2.3.4   OVPN_PORT=4443   OVPN_PROTO=tcp|udp
  OVPN_NET=10.8.0.0   OVPN_MASK=255.255.255.0
  CA_CN="OpenVPN-CA"  SERVER_CN="server"
  OVPN_DNS1=1.1.1.1   OVPN_DNS2=9.9.9.9

Examples:
  sudo SERVER_IP=185.232.155.233 $0 install
  sudo $0 add-user myphone
  sudo $0 del-user myphone
EOF
}

main() {
  need_root
  local cmd="${1:-}"
  case "${cmd}" in
    install)
      install_openvpn
      ;;
    add-user)
      shift || true
      gen_client "${1:-}"
      build_client_ovpn "${1:-}"
      ;;
    del-user)
      shift || true
      revoke_client "${1:-}"
      ;;
    make-ovpn)
      shift || true
      build_client_ovpn "${1:-}"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"

