# UBSan: member call on null pointer at renderer.hpp:339

- Cause: `Op::At` / the not-found-stack path (`include/inja/renderer.hpp:339`) dereferences `container` without checking it is non-null (`container->at(id_node->name)`), reachable from a malformed `at`/index expression.
- Impact: undefined behaviour (a null `json*` member call) on a crafted template; a crash under halting UBSan.
- Fix: check `container` for null and `throw_renderer_error` before dereferencing.
- Reproduce: `fuzz_render-standalone repro` (byte 0 is the option flags).
