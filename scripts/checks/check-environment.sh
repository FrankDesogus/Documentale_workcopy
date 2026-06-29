#!/usr/bin/env bash
set -u

ok() {
	printf "OK   - %s\n" "$1"
}

warn() {
	printf "WARN - %s\n" "$1"
}

fail() {
	printf "FAIL - %s\n" "$1"
}

check_cmd() {
	local cmd="$1"
	if command -v "$cmd" >/dev/null 2>&1; then
		ok "$cmd: $(command -v "$cmd")"
	else
		warn "$cmd non trovato"
	fi
}

echo "== Sistema =="
uname -a || true
echo "Shell: ${SHELL:-unknown}"

echo
echo "== Git =="
check_cmd git
git --version 2>/dev/null || true
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	ok "Dentro un repository Git"
else
	warn "Non sei dentro un repository Git"
fi
git status --short 2>/dev/null || true

echo
echo "== AI tools =="
check_cmd claude
claude --version 2>/dev/null || true

check_cmd codex
codex --version 2>/dev/null || true

check_cmd cursor
cursor --version 2>/dev/null || true

check_cmd agent
agent --version 2>/dev/null || true

echo
echo "== Utility =="
check_cmd jq
jq --version 2>/dev/null || true

check_cmd rg
rg --version 2>/dev/null | head -n 1 || true

check_cmd fd
fd --version 2>/dev/null || true

check_cmd fzf
fzf --version 2>/dev/null || true

check_cmd shellcheck
shellcheck --version 2>/dev/null | head -n 2 || true

check_cmd shfmt
shfmt --version 2>/dev/null || true

echo
echo "== Runtime =="
check_cmd node
node --version 2>/dev/null || true

check_cmd npm
npm --version 2>/dev/null || true

check_cmd python
python --version 2>/dev/null || true

echo
echo "== GPU / locale =="
check_cmd nvidia-smi
nvidia-smi 2>/dev/null | head -n 8 || true

check_cmd ollama
ollama --version 2>/dev/null || true
