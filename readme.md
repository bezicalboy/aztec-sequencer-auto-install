# 🌀 HELLARXN Aztec Sequencer Installer

No Docker. No drama. Just `bash` + `curl`.

## ⚡ What This Does

- Installs Node.js & Aztec CLI
- Grabs your RPC URLs and validator key
- Preps `.env` for sequencer config
- Runs `aztec-up alpha-testnet` like a boss

## 🔧 Requirements

- Ubuntu/Debian machine
- `sudo` privileges
- A working brain + RPC keys

## 🚀 Quickstart

```bash
curl -fsSL https://raw.githubusercontent.com/hellarxn/aztec-node/main/aztec.sh | bash
Or if you downloaded it:

bash
Copy
Edit
chmod +x aztec.sh
sudo ./aztec.sh
📥 You’ll Be Asked
L1 EL RPC URL (e.g. from Alchemy)

L1 CL RPC URL (e.g. from DRPC)

Optional Blob Sink URL

Validator Private Key

🗂 Output
.env with all your config

data/ folder for sequencer state

📓 Notes
Uses aztec-up alpha-testnet

You don’t need Docker to run this

Make sure you’re not behind CGNAT

🧠 Learn More
Aztec Docs: https://docs.aztec.network

🧪 Built for alpha-testnet by hellarxn

yaml
Copy
Edit

---

Need it to auto-run without prompts (headless style)? I can tweak the script to read from flags or `.env.template`. Want that?







