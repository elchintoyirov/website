#!/usr/bin/env bash
set -euo pipefail

ROOT="${DEPLOY_ROOT:-$HOME/elchintoyirov.uz}"
REPO="${DEPLOY_REPO:-$HOME/codebase/website}"
SITE="$ROOT/site"
BUILD="$ROOT/.build"
BRANCH="main"
ZOLA_IMAGE="ghcr.io/getzola/zola:v0.22.1"

cd "$REPO"

git fetch --quiet origin "$BRANCH"

if [ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$BRANCH")" ] && [ -f "$SITE/index.html" ]; then
    exit 0
fi

git reset --hard --quiet "origin/$BRANCH"
git submodule sync --quiet --recursive
git submodule update --init --recursive --quiet

rm -rf "$BUILD"
mkdir -p "$BUILD"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$REPO:/project" \
    --volume "$BUILD:/output" \
    --workdir /project \
    "$ZOLA_IMAGE" build --output-dir /output --force

test -f "$BUILD/index.html"

rsync -a --delete "$BUILD/" "$SITE/"
rm -rf "$BUILD"

echo "deployed $(git rev-parse --short HEAD) at $(date -Iseconds)"
