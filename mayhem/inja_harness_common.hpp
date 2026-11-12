#ifndef MAYHEM_INJA_HARNESS_COMMON_HPP_
#define MAYHEM_INJA_HARNESS_COMMON_HPP_

#include <string>

#include "inja/inja.hpp"

// A fresh Environment per input, configured the way an embedder rendering untrusted templates would:
// no filesystem lookups for include/extends, only in-memory templates registered below.
inline inja::Environment make_environment() {
  inja::Environment env;
  env.set_search_included_templates_in_files(false);
  env.include_template("inc", env.parse("[inc {{ name }}]"));
  env.include_template("base", env.parse("<{% block head %}H{% endblock %}|{% block body %}B{% endblock %}>"));
  return env;
}

inline inja::json make_data() {
  inja::json data;
  data["name"] = "Peter";
  data["city"] = "Brunswick";
  data["age"] = 29;
  data["pi"] = 3.14159;
  data["names"] = {"Jeff", "Seb", "Anna"};
  data["brother"]["name"] = "Chris";
  data["brother"]["daughters"] = {"Maria", "Helen"};
  data["brother"]["daughter0"] = {{"name", "Maria"}};
  data["is_happy"] = true;
  data["is_sad"] = false;
  data["empty"] = nullptr;
  data["relatives"]["mother"] = "Maria";
  data["relatives"]["sister"] = "Jenny";
  data["vars"] = {2, 3, 4, 0, -1, -2, -3};
  data["max_value"] = 18446744073709551615ull;
  data["html"] = "<b>&\"'</b>";
  return data;
}

#endif
