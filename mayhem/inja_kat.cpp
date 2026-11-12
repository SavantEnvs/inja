// Known-answer probe for mayhem/test.sh: inja_kat <template> <json> renders the template and prints the
// result (or `ERROR: <what>` on an inja error), so the shell compares exact strings.
#include <cstdio>
#include <iostream>

#include "inja/inja.hpp"

int main(int argc, char** argv) {
  if (argc != 3) {
    std::fputs("usage: inja_kat <template> <json>\n", stderr);
    return 2;
  }
  try {
    inja::Environment env;
    std::cout << env.render(argv[1], inja::json::parse(argv[2]));
  } catch (const inja::InjaError& e) {
    std::cout << "ERROR: " << e.what();
  }
  return 0;
}
