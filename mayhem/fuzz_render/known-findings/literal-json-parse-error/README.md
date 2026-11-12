# Malformed literal leaks nlohmann::json::parse_error

- Cause: `LiteralNode` (`include/inja/node.hpp:105`) calls `json::parse` on the literal text with exceptions enabled, so `{{ 1.2.3 }}`, `{{ [1,] }}` or `{{ {"a": } }}` throw `nlohmann::json::parse_error`, not `inja::ParserError`.
- Impact: callers catching only `inja::InjaError` terminate on a malformed literal. The harness catches `inja::json::exception` so this one does not mask other findings; the other two findings here are left uncaught.
- Fix: parse with `allow_exceptions=false` and raise a parser error on `is_discarded()`.
- Reproduce: `inja_kat '{{ 1.2.3 }}' '{}'` (built without that catch).
