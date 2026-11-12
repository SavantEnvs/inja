# `float("abc")` throws std::invalid_argument

Same cause and fix as `int-invalid-argument` (`renderer.hpp:383`, `std::stod`).
Reproduce: `fuzz_render-standalone repro`.
