# `int("abc")` throws std::invalid_argument

- Cause: `include/inja/renderer.hpp:386` calls `std::stoi` on the argument with no error handling; `float()` (line 383, `std::stod`) is the same.
- Impact: a template containing `{{ int("abc") }}` or `{{ float("abc") }}` terminates a caller that only catches `inja::InjaError`, which is what the README documents for ill-formed templates.
- Fix: catch `std::invalid_argument`/`std::out_of_range` in the `Op::Int`/`Op::Float` cases and `throw_renderer_error`.
- Reproduce: `fuzz_render-standalone repro` (byte 0 is the option flags, the rest is the template).
