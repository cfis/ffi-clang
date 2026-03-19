# Releases

## v0.16.0

  - Fix {ruby FFI::Clang::TranslationUnit\#default\_reparse\_options} calling wrong libclang function.
  - Add {ruby FFI::Clang::Types::Type\#unqualified\_type} to get a type with qualifiers removed (clang 16+).
  - Add {ruby FFI::Clang::Cursor\#binary\_operator\_kind} and {ruby FFI::Clang::Cursor.binary\_operator\_kind\_spelling} for binary operator cursors (clang 17+).
  - Add {ruby FFI::Clang::Cursor\#unary\_operator\_kind} and {ruby FFI::Clang::Cursor.unary\_operator\_kind\_spelling} for unary operator cursors (clang 17+).
  - Add {ruby FFI::Clang::Index.create\_with\_options} to create an index with extended options (clang 17+). Fix `CXIndexOptions` struct layout and add `CXChoice` enum.

## v0.15.0

  - {ruby FFI::Clang::Cursor\#find\_by\_kind} now returns an `Enumerator` instead of an `Array` when called without a block. This is a *breaking* change. Call `.to_a` if you need array indexing.
  - Auto-detect the clang resource directory to fix header resolution on platforms where libclang cannot find its own resource directory (e.g. Fedora's lib64 layout, MSVC-bundled clang on Windows). Supports `LIBCLANG_RESOURCE_DIR` environment variable for explicit override.

## v0.14.0

  - Helper method that returns a cursor's {ruby FFI::Clang::Cursor\#qualified\_display\_name}.
