#!/bin/bash

CHARTS=(
  "flash"
  "flash-deps"
  "flash-pay"
  "strfry"
  "nostr-multiplexer"
  "price"
)

REGISTRY="oci://ghcr.io/lnflash"

# Check if a specific chart was provided as argument
if [ -n "$1" ]; then
  # Validate that the provided chart exists in CHARTS array
  if [[ " ${CHARTS[@]} " =~ " $1 " ]]; then
    CHARTS=("$1")
    echo "Packaging single chart: $1"
  else
    echo "Error: Chart '$1' not found in available charts: ${CHARTS[@]}"
    exit 1
  fi
else
  echo "Packaging all charts..."
fi

for chart in "${CHARTS[@]}"; do
  echo "Processing $chart..."
  # flash bundles price via file://../price, but helm does not recurse into a
  # local subchart's own dependencies (and charts/price/charts/ is gitignored).
  # Without this, flash packages price WITHOUT its bitnami postgresql and the
  # next helm upgrade prunes the live price-history postgres from the cluster.
  if [ "$chart" = "flash" ]; then
    helm dependency update "charts/price"
  fi
  helm dependency update "charts/$chart"
  helm package "charts/$chart"

  # Push to registry (will skip if version exists)
  helm push ${chart}-*.tgz "$REGISTRY" 2>&1 | grep -v "already exists" || true

  # Clean up local package
  rm ${chart}-*.tgz
done