#!/bin/bash
set -eo pipefail

variants=(
  open
  blacklist
  whitelist
)

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
    cat <<'__EOF__' >/tmp/makefileSedExpressions
      # No need to change Makefile to open mode
__EOF__

    cat <<'__EOF__' >/tmp/opentrackerSedExpressions
    # Opentrack conf whitelist sed expressions
    sed -ri -e '\
      s!(.*)(tracker.user)(.*)!\2 opentracker!g; \
    ' /tmp/stage/etc/opentracker/opentracker.conf ; \
__EOF__

    ;;

  blacklist)
    cat <<'__EOF__' >/tmp/makefileSedExpressions
      # Makefile blacklist sed expressions
      sed -ri -e '\
        /^#.*DWANT_ACCESSLIST_BLACK/s/^#//; \
      ' Makefile ; \
__EOF__

    cat <<'__EOF__' >/tmp/opentrackerSedExpressions
      # Opentrack conf blacklist sed expressions
      sed -ri -e '\
        s!(.*)(tracker.user)(.*)!\2 opentracker!g; \
        s!(.*)(access.blacklist)(.*)!\2 /etc/opentracker/blacklist!g; \
      ' /tmp/stage/etc/opentracker/opentracker.conf ; \
      touch /tmp/stage/etc/opentracker/blacklist ; \
__EOF__

    ;;

  whitelist)
    cat <<'__EOF__' >/tmp/makefileSedExpressions
      # Makefile whitelist sed expressions
      sed -ri -e '\
        /^#.*DWANT_ACCESSLIST_WHITE/s/^#//; \
      ' Makefile ; \
__EOF__

    cat <<'__EOF__' >/tmp/opentrackerSedExpressions
      # Opentrack conf whitelist sed expressions
      sed -ri -e '\
        s!(.*)(tracker.user)(.*)!\2 opentracker!g; \
        s!(.*)(access.whitelist)(.*)!\2 /etc/opentracker/whitelist!g; \
      ' /tmp/stage/etc/opentracker/opentracker.conf ; \
      touch /tmp/stage/etc/opentracker/whitelist ; \
__EOF__

    ;;
  esac

  # Replace the variables.
  sed -i '/%%MAKEFILE_SED_EXPRESSIONS%%/ {
    r /tmp/makefileSedExpressions
    d
    }' "$variantFile"

  sed -i '/%%OPENTRACKER_CONF_SED_EXPRESSIONS%%/ {
    r /tmp/opentrackerSedExpressions
    d
    }' "$variantFile"

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
