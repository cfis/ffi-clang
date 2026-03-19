# Releases

## v0.16.0

### Platform Support

  - Add macOS support using Xcode's built-in clang/libclang.
  - Add Windows MSVC (mswin) support using Visual Studio's bundled LLVM/Clang, including system include path discovery via `vcvarsall.bat` and `clang-cl`.
  - Improve Windows MinGW support.
  - Work around LLVM bug [#154361](https://github.com/llvm/llvm-project/pull/171465) where `FreeLibrary` on `libclang.dll` crashes during process exit due to dangling Fiber Local Storage callbacks (fixed in LLVM 22.1.0).

### New APIs

  - **Cursor**: `invalid_declaration?`, `has_attrs?`, `visibility`, `storage_class`, `tls_kind`, `function_inlined?`, `macro_function_like?`, `macro_builtin?`, `has_global_storage?`, `has_external_storage?`, `inline_namespace?`, `mangling`, `offset_of_field`, `brief_comment_text`, `spelling_name_range`, `evaluate`.
  - **Type**: `address_space`, `typedef_name`, `transparent_tag_typedef?`, `nullability`, `modified_type`, `value_type`, `visit_fields`, `pretty_printed` (LLVM 21+), `fully_qualified_name` (LLVM 21+).
  - **TranslationUnit**: `target_triple`, `target_pointer_width`, `suspend`.
  - **File**: `real_path_name`, `==`.
  - **EvalResult**: New class for compile-time constant evaluation — `kind`, `as_int`, `as_long_long`, `unsigned_int?`, `as_unsigned`, `as_double`, `as_str`.

## v0.15.0

  - {ruby FFI::Clang::Cursor\#find\_by\_kind} now returns an `Enumerator` instead of an `Array` when called without a block. This is a *breaking* change. Call `.to_a` if you need array indexing.
  - Auto-detect the clang resource directory to fix header resolution on platforms where libclang cannot find its own resource directory (e.g. Fedora's lib64 layout, MSVC-bundled clang on Windows). Supports `LIBCLANG_RESOURCE_DIR` environment variable for explicit override.
  - Fix {ruby FFI::Clang::TranslationUnit\#default\_reparse\_options} calling wrong libclang function.
  - Add {ruby FFI::Clang::Types::Type\#unqualified\_type} to get a type with qualifiers removed (clang 16+).
  - Add {ruby FFI::Clang::Cursor\#binary\_operator\_kind} and {ruby FFI::Clang::Cursor.binary\_operator\_kind\_spelling} for binary operator cursors (clang 17+).
  - Add {ruby FFI::Clang::Cursor\#unary\_operator\_kind} and {ruby FFI::Clang::Cursor.unary\_operator\_kind\_spelling} for unary operator cursors (clang 17+).
  - Add {ruby FFI::Clang::Index.create\_with\_options} to create an index with extended options (clang 17+). Fix `CXIndexOptions` struct layout and add `CXChoice` enum.

## v0.14.0

  - Helper method that returns a cursor's {ruby FFI::Clang::Cursor\#qualified\_display\_name}.
