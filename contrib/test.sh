#!/bin/sh
#
# CI test script for rust-bech32.

set -eu
set -x

# Some tests require certain toolchain types.
NIGHTLY=false
if cargo --version | grep nightly; then
    NIGHTLY=true
fi

build_and_test () {
    cargo build --no-default-features --features="$1"
    cargo test --no-default-features --features="$1"
}

# Sanity, check tools exist.
cargo --version
rustc --version

# Run the linter if told to.
if [ "${DO_LINT-false}" = true ]
then
    cargo clippy --all-features --all-targets -- -D warnings
fi

# Run formatter if told to.
if [ "${DO_FMT-false}" = true ]; then
    if [ "$NIGHTLY" = false ]; then
        echo "DO_FMT requires a nightly toolchain (consider using RUSTUP_TOOLCHAIN)"
        exit 1
    fi
    rustup component add rustfmt
    cargo fmt --check
fi

if [ "${DO_FEATURE_MATRIX-false}" = true ]; then
    # No features
    build_and_test ""
    # Feature combos (currently no features or dependncies in library)
fi

# Build the docs if told to (this only works with the nightly toolchain)
if [ "${DO_DOCSRS-false}" = true ]; then
    RUSTDOCFLAGS="--cfg docsrs -D warnings -D rustdoc::broken-intra-doc-links" cargo +nightly doc --all-features
fi

# Build the docs with a stable toolchain, in unison with the DO_DOCSRS command
# above this checks that we feature guarded docs imports correctly.
if [ "${DO_DOCS-false}" = true ]; then
    RUSTDOCFLAGS="-D warnings" cargo +stable doc --all-features
fi

exit 0
