#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils curl jq
set -euo pipefail

version=$(curl -s "https://crates.io/api/v1/crates/goldboot" | jq -r '.crate.newest_version')
update-source-version goldboot "${version}"

# TODO update hashes
