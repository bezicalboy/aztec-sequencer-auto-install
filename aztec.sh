#!/usr/bin/env bash
set -euo pipefail

# ──────── ⚔️ Aesthetic Terminal Vibes ─────────
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║         HELLARXN • AZTEC ONE-CLICK SEQUENCER        ║
╠══════════════════════════════════════════════════════╣
║  Automatic setup. No Docker drama. No RPC chaos.     ║
║  We cook nodes. You claim blocks.                    ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# ──────── Root Enforcement ─────────
if [[ $EUID -ne 0 ]]; then
  echo "❌ Must be run as root. Use: sudo ./aztec-hellarxn.sh"
  exit 1
fi

# ──────── Docker Check ─────────
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  apt-get update && apt-get install -y docker.io
fi

if ! docker compose version &> /dev/null; then
  echo "🔧 Installing Docker Compose Plugin..."
  apt-get install -y docker-compose-plugin
fi

# ──────── Node.js Check ─────────
if ! command -v node &> /dev/null; then
  echo "🟢 Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
  apt-get install -y nodejs
fi

# ──────── Aztec CLI Check ─────────
if ! command -v aztec-up &> /dev/null; then
  echo "🌐 Installing Aztec CLI..."
  curl -sL https://install.aztec.network | bash
  export PATH="$HOME/.aztec/bin:$PATH"
fi

# ──────── Kickstart Node Setup ─────────
aztec-up alpha-testnet

# ──────── User Input ─────────
echo -e "\n📋 Fill in your node credentials:"
read -rp "🔹 ALCHEMY RPC URL (example: https://eth-sepolia.g.alchemy.com/v2/YOUR API KEY ) : " ETH_RPC
read -rp "🔹 DRPC RPC URL (example: https://lb.drpc.org/ogrpc?network=sepolia&dkey=YOUR API KEY ) : " CONS_RPC
read -rp "🔹 Blob URL (optional): " BLOB_URL
read -rp "🔐 Validator Private Key: " VALIDATOR_PRIVATE_KEY

# ──────── IP Grab ─────────
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "🌍 Using Public IP: $PUBLIC_IP"

# ──────── .env Write ─────────
cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

[[ -n "$BLOB_URL" ]] && echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env

# ──────── Docker Compose ─────────
mkdir -p data

cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  hellarxn-node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.5
    network_mode: host
    env_file: .env
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer ${BLOB_SINK_URL:+--sequencer.blobSinkUrl $BLOB_SINK_URL}'
    volumes:
      - ./data:/data
EOF

# ──────── Launch ─────────
echo -e "\n🚀 Launching your Aztec node, commander Hellarxn..."
docker compose up -d

echo -e "\n✅ Done. Logs? Use:"
echo "   docker compose logs -f hellarxn-node"
