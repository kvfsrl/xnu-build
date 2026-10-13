#!/bin/bash
#
# build-xnu.sh - build Apple's XNU (Darwin) kernel from source.
#
# NOTE: XNU's build system is hard-wired to Apple's toolchain. It needs
# /usr/bin/xcrun, /usr/bin/xcodebuild, the Apple cctools (ctfconvert,
# ctfmerge, dsymutil, kextsymboltool, setsegname) and a macOS SDK. It
# therefore only builds on macOS. This script refuses to run elsewhere.
#
# Usage:
#   ARCH=arm64  CONFIG=RELEASE  SDK=macosx  JOBS=8  ./build-xnu.sh
#
set -euo pipefail

ARCH_CONFIGS="${ARCH_CONFIGS:-}"
if [ -z "$ARCH_CONFIGS" ]; then
  case "$(uname -m)" in
    arm64|aarch64) ARCH_CONFIGS=ARM64 ;;
    x86_64|amd64)  ARCH_CONFIGS=X86_64 ;;
    *) echo "error: unknown host arch '$(uname -m)', set ARCH_CONFIGS" >&2; exit 1 ;;
  esac
fi

CONFIG="${CONFIG:-RELEASE}"
SDK="${SDK:-macosx}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

if [ "$(uname -s)" != "Darwin" ]; then
  cat >&2 <<'EOF'
error: this host is not macOS.

Apple's XNU build system cannot run on Linux. A real build requires:

  * macOS with Xcode (or full Command Line Tools), providing:
      /usr/bin/xcrun, /usr/bin/xcodebuild
      ctfconvert, ctfmerge, dsymutil, kextsymboltool, setsegname
  * a macOS SDK                    (SDKROOT=macosx)
  * for arm64 targets, a matching Kernel Development Kit (KDK)
    installed under /Library/Developer/KDKs

On macOS run:   ./build-xnu.sh

On Linux the only supported route to a real kernel binary is a
macOS CI runner - see .github/workflows/build-xnu.yml
EOF
  exit 2
fi

cd "$(dirname "$0")"

echo ">> XNU build: ARCH_CONFIGS=$ARCH_CONFIGS KERNEL_CONFIGS=$CONFIG SDKROOT=$SDK"
make SDKROOT="$SDK" \
     ARCH_CONFIGS="$ARCH_CONFIGS" \
     KERNEL_CONFIGS="$CONFIG" \
     MAKEJOBS="-j$JOBS" \
     all

echo ">> artifacts:"
find BUILD -type f \( -name 'kernel.*' -o -name '*.dSYM' \) 2>/dev/null | sort
