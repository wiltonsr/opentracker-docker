#!/bin/bash
set -eo pipefail

variants=(
  open
  blacklist
  whitelist
)

function create_variant() {
  declare -a features=(
    "-DWANT_FULLSCRAPE"
    "-DWANT_FULLLOG_NETWORKS"
    "-DWANT_LOG_NUMWANT"
    "-DWANT_MODEST_FULLSCRAPES"
    "-DWANT_SPOT_WOODPECKER"
  )

  variant=$1
  variant_file="$variant.Dockerfile"

  touch "${variant_file}"

  template="Dockerfile.template"

  cat <<__EOF__ >"${variant_file}"
#
# NOTE: THIS DOCKERFILE IS GENERATED VIA update.sh from ${template}
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
__EOF__

  cat "$template" >>"$variant_file"

  echo "updating $variant_file"

  case "$variant" in
  open)
    features+=()
    extra_sed_confs=''
    ;;

  blacklist)
    features+=("-DWANT_ACCESSLIST_BLACK")
    extra_sed_confs="-e 's!(.*)(access.blacklist)(.*)!\\\2 /etc/opentracker/blacklist!g;'"
    ;;

  whitelist)
    features+=("-DWANT_ACCESSLIST_WHITE")
    extra_sed_confs="-e 's!(.*)(access.whitelist)(.*)!\\\2 /etc/opentracker/whitelist!g;'"
    ;;

  esac

  features_sed_string=''
  for i in "${features[@]}"; do
    # Add extra slashes to escape on below sed substitution
    features_sed_string+="FEATURES+=${i} \\\\\n  "
  done

  # Replace MAKEFILE_FEATURES variable from template
  sed -ri \
    -e 's@%%MAKEFILE_FEATURES%%@'"${features_sed_string}"'@g;' \
    "$variant_file"

  # Replace OPENTRACKER_CONFS variable from template
  sed -ri \
    -e 's@%%OPENTRACKER_CONFS%%@'"${extra_sed_confs}"'@g;' \
    "$variant_file"
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
