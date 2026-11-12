# Signed integer overflow in `+` on INT64_MAX

- Cause: `include/inja/renderer.hpp:284` adds two `number_integer_t` values with no overflow check.
- Impact: signed-overflow UB for any template adding to a near-limit integer from user data (`{{ n + 1 }}` with `n = 9223372036854775807`); a crash under halting UBSan. `-`/`*` have the same shape.
- Fix: use `__builtin_add_overflow` and fall back to a float result or raise a render error.
- Reproduce: `fuzz_render_json-standalone repro` (template, NUL, JSON).
