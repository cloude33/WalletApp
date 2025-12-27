#!/bin/sh
# Clean extended attributes before build
find "$BUILT_PRODUCTS_DIR" -name "*.framework" -exec xattr -cr {} \; 2>/dev/null || true
find "$BUILT_PRODUCTS_DIR" -name "*.app" -exec xattr -cr {} \; 2>/dev/null || true
