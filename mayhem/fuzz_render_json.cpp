// Fuzzes inja's renderer against attacker-shaped data: input is `<template> NUL <json document>`.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <string_view>

#include "inja_harness_common.hpp"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  const uint8_t* sep = std::find(data, data + size, uint8_t{0});
  if (sep == data + size) {
    return -1;
  }
  const std::string_view tmpl(reinterpret_cast<const char*>(data), static_cast<size_t>(sep - data));
  const std::string_view doc(reinterpret_cast<const char*>(sep) + 1, static_cast<size_t>(data + size - sep - 1));

  inja::json json_data = inja::json::parse(doc, nullptr, false);
  if (json_data.is_discarded()) {
    return -1;
  }

  inja::Environment env = make_environment();
  try {
    env.render(tmpl, json_data);
  } catch (const inja::InjaError&) {
  } catch (const inja::json::exception&) {
    // inja leaks the data library's own exception (e.g. LiteralNode on a malformed literal); see known-findings/
  }
  return 0;
}
