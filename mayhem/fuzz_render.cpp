// Fuzzes inja's lexer, parser and renderer: byte 0 selects the Environment options, the rest is the
// template, rendered against a fixed data set.
#include <cstddef>
#include <cstdint>
#include <string_view>

#include "inja_harness_common.hpp"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  if (size < 1) {
    return -1;
  }
  const uint8_t flags = data[0];
  const std::string_view tmpl(reinterpret_cast<const char*>(data) + 1, size - 1);

  inja::Environment env = make_environment();
  env.set_html_autoescape(flags & 1);
  env.set_trim_blocks(flags & 2);
  env.set_lstrip_blocks(flags & 4);
  env.set_throw_at_missing_includes(flags & 8);

  try {
    env.render(tmpl, make_data());
  } catch (const inja::InjaError&) {
  } catch (const inja::json::exception&) {
    // inja leaks the data library's own exception (e.g. LiteralNode on a malformed literal); see known-findings/
  }
  return 0;
}
