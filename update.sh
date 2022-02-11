#!/bin/bash -x
set -eo pipefail

variants=(
  open
  blacklist
  whitelist
)

features='FEATURES+=-DWANT_FULLSCRAPE \\\n      FEATURES+=-DWANT_FULLLOG_NETWORKS \\\n      FEATURES+=-DWANT_LOG_NUMWANT \\\n      FEATURES+=-DWANT_MODEST_FULLSCRAPES \\\n      FEATURES+=-DWANT_SPOT_WOODPECKER'

function create_variant() {
  variant=$1
  variantFile="$variant.Dockerfile"

  touch "${variantFile}"

  template="Dockerfile.template"

  cat <<__EOF__ >"${variantFile}"
#
# NOTE: THIS DOCKERFILE IS GENERATED VIA update.sh from ${template}
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
__EOF__

  cat "$template" >>"$variantFile"

  echo "updating $variantFile"

  case "$variant" in
  open)
    :
    ;;

  blacklist)
    features="${features} \\\\\n      FEATURES+=-DWANT_ACCESSLIST_BLACK"
    ;;

  whitelist)
    features="${features} \\\\\n      FEATURES+=-DWANT_ACCESSLIST_WHITE"
    ;;

  esac

  # Replace the variables.
  sed -ri -e '
    s@%%MAKEFILE_FEATURES%%@'"${features}"'@g;
  ' "$variantFile"
}

if [ -z "$1" ]; then
  for variant in "${variants[@]}"; do
    create_variant "$variant"
  done
elif [[ ${variants[*]} =~ $1 ]]; then
  create_variant "$1"
else
  echo "Value ${1} Invalid!"
  exit 1
fi
