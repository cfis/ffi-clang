// Forward declaration
struct ForwardDeclared;

// Use of forward-declared type as pointer
ForwardDeclared *forward_ptr;

// Full definition
struct ForwardDeclared {
	int value;
};

// Pointer to fully-defined type
struct FullyDefined {
	int x;
};
FullyDefined *full_ptr;
