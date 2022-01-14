#!/bin/bash
set -euo pipefail

chown_r_dir() {
  dir=$1
  if [[ -d ${dir} ]] && [[ "$(stat -c %u:%g ${dir})" != "1000:1000" ]]; then
    echo chown -R $dir
    chown -R ci:ci $dir
  fi
}

chown_r_dir /plugin
if [[ -S /var/run/docker.sock ]]; then
  chown root:docker /var/run/docker.sock
  chmod g+w /var/run/docker.sock
fi

if [ "$1" = 'bash' ]; then
  exec /bin/bash
fi

exec su-exec ci "$@"
