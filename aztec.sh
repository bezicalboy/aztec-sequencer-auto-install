#!/usr/bin/env bash
set -euo pipefail
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  apt-get update && apt-get install -y docker.io
fi

if ! docker compose version &>/dev/null; then
  echo "🔧 Installing Docker Compose Plugin..."
  apt-get install -y docker-compose-plugin
fi

# ─── DEPENDENCY: Node.js ──────────────────────────────────────────────────────
if ! command -v node &> /dev/null; then
  echo "🟢 Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
  apt-get install -y nodejs
fi

# ─── Install Aztec CLI ────────────────────────────────────────────────────────
if ! command -v aztec-up &> /dev/null; then
  echo "🌐 Installing Aztec CLI..."
  curl -sL https://install.aztec.network | bash
  export PATH="$HOME/.aztec/bin:$PATH"
fi

# ─── Run CLI Setup ────────────────────────────────────────────────────────────
aztec-up alpha-testnet

# ─── Prompt User for Config ───────────────────────────────────────────────────
echo -e "Enter RPC:"

read -rp "ALCHEMY SEPOLIA RPC URL: " ETH_RPC
read -rp "DRPC BEACON SEPOLIA RPC URL: " CONS_RPC
read -rp "Blob Sink URL, just hit enter bro: " BLOB_URL
read -rp "Private Key with 0x: " VALIDATOR_PRIVATE_KEY

# ─── Public IP ────────────────────────────────────────────────────────────────
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "IP: $PUBLIC_IP"

# ─── Write .env ───────────────────────────────────────────────────────────────
cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

[[ -n "$BLOB_URL" ]] && echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env

# ─── Write Docker Compose ─────────────────────────────────────────────────────
mkdir -p data

cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.5
    network_mode: host
    env_file: .env
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer ${BLOB_SINK_URL:+--sequencer.blobSinkUrl $BLOB_SINK_URL}'
    volumes:
      - ./data:/data
EOF

# ─── Launch ───────────────────────────────────────────────────────────────────
echo -e "🚀 Launching node..."
docker compose up -d

echo -e " All done! Use this to check logs:"
echo "   docker compose logs -f"
