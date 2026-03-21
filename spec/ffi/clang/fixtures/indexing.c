#include "extra.h"

int global_value = 7;

int use_global(int value)
{
	return global_value + value + extra_function();
}
