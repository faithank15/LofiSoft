#!/usr/bin/env bash
# Exercice « refaire de zéro » : on supprime les fichiers d'une étape (sur une branche à part),
# on les réécrit, et les tests existants servent d'énoncé.
#
#   ./documents/apprendre/exercice.sh liste
#   ./documents/apprendre/exercice.sh start    <id>   # crée la branche exercice/<id>, supprime les fichiers
#   ./documents/apprendre/exercice.sh check    <id>   # lance les tests de l'étape
#   ./documents/apprendre/exercice.sh solution <id>   # range votre version, remet l'original, montre les écarts
#   ./documents/apprendre/exercice.sh quitter  <id>   # revient sur main et supprime la branche d'exercice
#
# Aucune commande ne pousse quoi que ce soit : tout reste local, sur la branche exercice/<id>.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
DEF=documents/apprendre/exercices.txt
SAVE=.exercices
BASE=main

cmd=${1:-aide}
id=${2:-}

ligne() { grep -v '^#' "$DEF" | awk -F' *\\| *' -v id="$1" '$1==id {print; exit}'; }

if [[ $cmd == liste || $cmd == aide ]]; then
  echo "Étapes disponibles :"
  grep -v '^#' "$DEF" | awk -F' *\\| *' '{printf "  %-18s %s\n", $1, $5}'
  echo
  echo "Usage : $0 start|check|solution|quitter <id>"
  exit 0
fi

[[ -n $id ]] || { echo "Indiquez l'étape (voir : $0 liste)"; exit 1; }
row=$(ligne "$id")
[[ -n $row ]] || { echo "Étape inconnue : $id"; exit 1; }
dossier=$(echo "$row" | awk -F' *\\| *' '{print $2}')
tests=$(echo "$row" | awk -F' *\\| *' '{print $3}')
files=$(echo "$row" | awk -F' *\\| *' '{print $4}')
branch="exercice/$id"
current=$(git branch --show-current)

case $cmd in
  start)
    if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
      echo "Des modifications non commitées existent. Commitez-les d'abord (ou stash), puis relancez."; exit 1
    fi
    if [[ $current == "$BASE" ]]; then
      git switch -c "$branch"
    elif [[ $current != "$branch" ]]; then
      echo "Vous êtes sur '$current'. Revenez sur $BASE avant de commencer un exercice."; exit 1
    fi
    for f in $files; do git rm -q -f "$dossier/$f"; done
    echo
    echo "Branche : $branch"
    echo "Fichiers supprimés (à réécrire à partir de rien) :"
    for f in $files; do echo "  $dossier/$f"; done
    echo
    echo "Les tests sont votre énoncé : lisez-les, puis réécrivez les fichiers."
    echo "Vérifier : $0 check $id      (ou : cd $dossier && $tests)"
    ;;
  check)
    cd "$dossier"
    # shellcheck disable=SC2086
    $tests
    ;;
  solution)
    [[ $current == "$branch" ]] || { echo "Placez-vous d'abord sur $branch."; exit 1; }
    mkdir -p "$SAVE/$id"
    for f in $files; do
      if [[ -f "$dossier/$f" ]]; then
        mkdir -p "$SAVE/$id/$(dirname "$f")"; cp "$dossier/$f" "$SAVE/$id/$f"
      fi
      git checkout "$BASE" -- "$dossier/$f"
    done
    echo "Votre version est rangée dans $SAVE/$id/. L'original est remis en place."
    echo "Comparer :"
    for f in $files; do echo "  diff -u $SAVE/$id/$f $dossier/$f | less"; done
    ;;
  quitter)
    read -r -p "Abandonner la branche $branch (votre travail est copié dans $SAVE/$id) ? [o/N] " ok
    [[ $ok == o || $ok == O ]] || exit 0
    mkdir -p "$SAVE/$id"
    for f in $files; do
      if [[ -f "$dossier/$f" ]]; then mkdir -p "$SAVE/$id/$(dirname "$f")"; cp "$dossier/$f" "$SAVE/$id/$f"; fi
    done
    git reset -q --hard
    git switch -q "$BASE"
    git branch -q -D "$branch"
    echo "De retour sur $BASE. Votre travail est dans $SAVE/$id/."
    ;;
  *) echo "Commande inconnue : $cmd"; exit 1 ;;
esac
