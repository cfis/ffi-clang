// Fixture for testing additional cursor and type APIs.

// Storage class
extern int extern_var;
static int static_var = 42;
int global_var = 0;

// Inline function
inline int inline_func(int x) { return x + 1; }

// Visibility (GCC/Clang attribute)
__attribute__((visibility("hidden"))) void hidden_func() {}
__attribute__((visibility("default"))) void visible_func() {}

// Struct with fields for visit_fields and offset_of_field
struct FieldStruct {
  int field_a;
  double field_b;
  char field_c;
};

// Inline namespace
namespace Outer {
  inline namespace InlineNS {
    void inline_ns_func() {}
  }
}

// Brief comment test
/// Brief comment on this function.
void documented_func() {}

// Namespace for fully qualified name testing
namespace MyNamespace {
  struct MyStruct {
    int value;
  };
}

// Variable with initializer
int initialized_var = 100;
int uninitialized_var;

// C++ class with inheritance for visit_base_classes and offset_of_base
struct Base1 {
  int base1_val;
};

struct Base2 {
  double base2_val;
};

struct Derived : public Base1, public Base2 {
  char derived_val;
  void derived_method() {}
  int another_method() { return 0; }
};

// Function-like macro (will appear as macro_definition cursor)
#define FUNC_MACRO(x) ((x) * 2)
#define CONST_MACRO 42

// Target info is tested via translation_unit, no fixture needed.
