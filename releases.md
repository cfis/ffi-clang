# Releases

## v0.15.0

  - {ruby FFI::Clang::Cursor\#find\_by\_kind} now returns an `Enumerator` instead of an `Array` when called without a block. This is a *breaking* change. Call `.to_a` if you need array indexing.
  - Auto-detect the clang resource directory to fix header resolution on platforms where libclang cannot find its own resource directory (e.g. Fedora's lib64 layout, MSVC-bundled clang on Windows). Supports `LIBCLANG_RESOURCE_DIR` environment variable for explicit override.

## v0.14.0

  - Helper method that returns a cursor's {ruby FFI::Clang::Cursor\#qualified\_display\_name}.
