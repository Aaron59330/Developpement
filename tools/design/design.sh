#!/usr/bin/env bash
# Bascule d'un coup tous les designs (HUD, notifications, aide, inventaire, voix, dialogues…).
#   ./tools/design/design.sh ancien   -> remet les anciens designs (état d'avant Arcade)
#   ./tools/design/design.sh arcade   -> remet le design Arcade
# Les fichiers nouveaux (arcade.css…) sont retirés pour « ancien » ; fxmanifest/index.html reviennent à leur version d'origine.
set -euo pipefail
cd "$(dirname "$0")/../.."
mode="${1:-}"; [[ "$mode" == ancien || "$mode" == arcade ]] || { echo "usage: $0 ancien|arcade"; exit 1; }
n=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  src="tools/design/$mode/$f"
  if [[ -f "$src" ]]; then mkdir -p "$(dirname "$f")"; cp "$src" "$f"
  else rm -f "$f"; fi        # absent de « ancien » = fichier créé par Arcade
  n=$((n+1))
done < tools/design/fichiers.txt
echo "Design « $mode » appliqué ($n fichiers). Ensuite en jeu : refresh puis restart des ressources listées dans tools/design/README.md"
