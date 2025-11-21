#!/bin/bash

CHARTS=(
  "flash"
  "flash-deps"
  "flash-pay"
  "strfry"
  "nostr-multiplexer"
  "price"
)

REGISTRY="oci://ghcr.io/brh28"

for chart in "${CHARTS[@]}"; do
  echo "Processing $chart..."
  helm dependency update "charts/$chart"
  helm package "charts/$chart"

  # Push to registry (will skip if version exists)
  helm push ${chart}-*.tgz "$REGISTRY" 2>&1 | grep -v "already exists" || true

  # Clean up local package
  rm ${chart}-*.tgz
done