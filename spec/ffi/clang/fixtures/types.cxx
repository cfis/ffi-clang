// Test fixture for additional type and cursor coverage

// Vector type (SIMD)
typedef int v4si __attribute__((vector_size(16)));
v4si my_vector;

// Function pointer
typedef int (*func_ptr)(int, float);
func_ptr my_func_ptr;

// Simple struct for record type tests
struct SimpleStruct {
	int x;
	float y;
};

// Union for record type tests
union SimpleUnion {
	int i;
	float f;
};

struct SimpleStruct my_struct;
union SimpleUnion my_union;

// Typedef for anonymous struct
typedef struct {
	int a;
	int b;
} AnonTypedef;

// Typedef for non-anonymous struct
typedef struct SimpleStruct NamedTypedef;

// Elaborated type pointer - typedef of a pointer to struct
typedef struct SimpleStruct *StructPtr;

// Scoped enum
enum class ScopedEnum {
	Value1,
	Value2
};

// Deleted function
struct DeletedCopy {
	DeletedCopy() = default;
	DeletedCopy(const DeletedCopy&) = delete;
	DeletedCopy& operator=(const DeletedCopy&) = default;
	DeletedCopy& operator=(DeletedCopy&&) = default;
};

// Explicit constructor
struct ExplicitCtor {
	explicit ExplicitCtor(int x);
};

// Const method
struct ConstMethod {
	int getValue() const;
	void setValue(int v);
};
