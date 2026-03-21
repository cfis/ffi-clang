// Fixture for additional type API coverage.

#define MY_ENUM(_name) typedef enum _name _name; enum _name

MY_ENUM(TransparentEnum) {
	TransparentEnumA
};

typedef int AliasInt;

_Atomic(int) atomic_counter;
