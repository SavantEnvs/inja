#!/usr/bin/env bash
#
# mayhem/build.sh — build inja's fuzz harnesses (sanitized, libFuzzer + standalone), the upstream doctest
# suite and a known-answer probe (both with normal flags). inja is header-only, so the "project" is
# compiled into each harness object; nothing is fetched, so the build is air-gapped and re-runnable.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

SRC="${SRC:-/mayhem}"
cd "$SRC"

B="$SRC/build"     # gitignored upstream (`build`), so `git clean -ffdX` removes it
mkdir -p "$B"

INCLUDES="-I$SRC/include -I$SRC/third_party/include -I$SRC/mayhem"

# 1) Fuzz harnesses. The library is header-only, so SanCov (fuzzer-no-link) + sanitizers go on the
#    harness translation unit that instantiates it. Compile each once, link twice (libFuzzer + standalone).
# shellcheck disable=SC2086
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -c "$STANDALONE_FUZZ_MAIN" -o "$B/standalone_main.o"
# shellcheck disable=SC2086
$CXX $SANITIZER_FLAGS $DEBUG_FLAGS -c "$SRC/mayhem/lsan_off.cc" -o "$B/lsan_off.o"

for t in fuzz_render fuzz_render_json; do
  # shellcheck disable=SC2086
  $CXX -std=c++17 -O1 $SANITIZER_FLAGS -fsanitize=fuzzer-no-link $DEBUG_FLAGS $INCLUDES \
      -c "$SRC/mayhem/$t.cpp" -o "$B/$t.o"
  # shellcheck disable=SC2086
  $CXX $SANITIZER_FLAGS $DEBUG_FLAGS $LIB_FUZZING_ENGINE "$B/$t.o" "$B/lsan_off.o" -o "$SRC/$t"
  # shellcheck disable=SC2086
  $CXX $SANITIZER_FLAGS $DEBUG_FLAGS "$B/$t.o" "$B/standalone_main.o" "$B/lsan_off.o" -o "$SRC/$t-standalone"
done

# 2) The upstream doctest suite and the known-answer probe, with the project's NORMAL flags (no
#    sanitizers, no DWARF pin): an independent build, so test.sh stays an honest oracle.
# shellcheck disable=SC2086
$CXX -std=c++17 -O1 $COVERAGE_FLAGS -D__TEST_DIR__="$SRC/test" $INCLUDES \
    "$SRC/test/test.cpp" -o "$SRC/inja_test"
# shellcheck disable=SC2086
$CXX -std=c++17 -O1 $COVERAGE_FLAGS $INCLUDES "$SRC/mayhem/inja_kat.cpp" -o "$SRC/inja_kat"

echo "build.sh: done"
