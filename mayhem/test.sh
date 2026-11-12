#!/usr/bin/env bash
#
# mayhem/test.sh — RUN inja's own doctest suite plus known-answer probes (both built by build.sh).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
SRC="${SRC:-/mayhem}"
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

for bin in inja_test inja_kat; do
  [ -x "$SRC/$bin" ] || { echo "test.sh: $SRC/$bin missing — build.sh must produce it" >&2; emit_ctrf inja 0 1; exit 1; }
done

passed=0; failed=0

# 1) upstream doctest suite: parse its assertion summary (every assertion must pass) (empty output, e.g. a neutered binary, matches nothing).
out="$("$SRC/inja_test" 2>&1)"
echo "$out" | tail -n 5
cases="$(sed -n 's/^\[doctest\] assertions: *\([0-9]*\) | *\([0-9]*\) passed | *\([0-9]*\) failed.*/\1 \2 \3/p' <<<"$out")"
if [ -z "$cases" ]; then
  echo "FAIL doctest: no summary line" >&2; failed=$((failed + 1))
else
  read -r total ok bad <<<"$cases"
  if [ "$total" -ge 250 ] && [ "$bad" -eq 0 ] && [ "$ok" -eq "$total" ]; then
    passed=$((passed + 1))
  else
    echo "FAIL doctest: total=$total passed=$ok failed=$bad" >&2; failed=$((failed + 1))
  fi
fi

# 2) known-answer probes: fixed template + data -> exact expected string.
kat() {
  local want="$1" tmpl="$2" json="$3" got
  got="$("$SRC/inja_kat" "$tmpl" "$json")"
  if [ "$got" == "$want" ]; then passed=$((passed + 1)); else
    echo "FAIL kat: '$tmpl' => '$got' (want '$want')" >&2; failed=$((failed + 1)); fi
}
kat 'Hello Peter!' 'Hello {{ name }}!' '{"name":"Peter"}'
kat '2,3,4,' '{% for v in vars %}{{ v }},{% endfor %}' '{"vars":[2,3,4]}'
kat 'big' '{% if age > 18 %}big{% else %}small{% endif %}' '{"age":29}'
kat 'JEFF/seb/3' '{{ upper(a) }}/{{ lower(b) }}/{{ length(c) }}' '{"a":"jeff","b":"SEB","c":[1,2,3]}'
kat '1-3-2' '{{ min(x) }}-{{ max(x) }}-{{ at(x, 2) }}' '{"x":[3,1,2]}'
kat '3.14 7' '{{ round(pi, 2) }} {% set n = 3 + 4 %}{{ n }}' '{"pi":3.14159}'
kat 'ERROR: [inja.exception.render_error] (at 1:4) variable '"'"'unknown'"'"' not found' '{{ unknown }}' '{}'
kat 'ERROR: [inja.exception.parser_error] (at 1:3) expected expression close, got '"'"'<eof>'"'"'' '{{' '{}'

emit_ctrf inja-doctest-kat "$passed" "$failed"
