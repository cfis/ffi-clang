// Forward declaration
struct ForwardDeclared;

// Usage of forward declaration
struct ForwardDeclared *forward_ptr;

// Full definition
struct ForwardDeclared {
	int value;
};

// Non-forward pointer
struct FullyDefined {
	int x;
};
struct FullyDefined *full_ptr;
