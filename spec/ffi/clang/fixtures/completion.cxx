#include <vector>

std::vector<int> v1;
std::vector<> v2;

struct Annotated {
  __attribute__((annotate("my_annotation"))) void annotated_method();
};

Annotated ann;

void complete_vector() {
  v1.
}

void complete_annotated() {
  ann.
}
