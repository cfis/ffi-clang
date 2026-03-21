# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013, by Dave Wilkinson.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2023, by Charlie Savage.

require_relative "lib/index"
require_relative "error"
require_relative "invocation_support"

module FFI
	module Clang
		# Represents a libclang index that manages translation units and provides a top-level context for parsing.
		class Index < AutoPointer
			include InvocationSupport
			
			# Initialize a new index for managing translation units.
			# @parameter exclude_declarations [Boolean] Whether to exclude declarations from PCH.
			# @parameter display_diagnostics [Boolean] Whether to display diagnostics during parsing.
			def initialize(exclude_declarations = true, display_diagnostics = false)
				super Lib.create_index(exclude_declarations ? 1 : 0, display_diagnostics ? 1 : 0)
			end
			
			# Create a new index with extended options (clang 17+).
			# @parameter options [Lib::CXIndexOptions] The index options struct.
			# @returns [Index] A new index instance.
			def self.create_with_options(options)
				instance = allocate
				FFI::AutoPointer.instance_method(:initialize).bind_call(instance, Lib.create_index_with_options(options))
				instance
			end
			
			# Release the index pointer.
			# @parameter pointer [FFI::Pointer] The index pointer to release.
			def self.release(pointer)
				Lib.dispose_index(pointer)
			end
			
			# Parse a source file and create a translation unit.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit(source_file, command_line_args = nil, unsaved = [], opts = {})
				parse_translation_unit_with(:parse_translation_unit2, source_file, command_line_args, unsaved, opts)
			end
			
			# Parse a source file using a full compiler command line including argv[0].
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Full compiler arguments including argv[0].
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit_with_invocation(source_file, command_line_args = nil, unsaved = [], opts = {})
				parse_translation_unit_with(:parse_translation_unit2_full_argv, source_file, command_line_args, unsaved, opts)
			end
			
			# Create a translation unit from a precompiled AST file.
			# @parameter ast_filename [String] The path to the AST file.
			# @returns [TranslationUnit] The loaded translation unit.
			# @raises [Error] If loading the AST file fails.
			def create_translation_unit(ast_filename)
				translation_unit_pointer = Lib.create_translation_unit(self, ast_filename)
				raise Error, "error parsing #{ast_filename.inspect}" if translation_unit_pointer.null?
				TranslationUnit.new translation_unit_pointer, self
			end
			
			# Create a translation unit from a precompiled AST file with detailed error reporting.
			# @parameter ast_filename [String] The path to the AST file.
			# @returns [TranslationUnit] The loaded translation unit.
			# @raises [Error] If loading the AST file fails.
			def create_translation_unit2(ast_filename)
				translation_unit_pointer_out = MemoryPointer.new(:pointer)
				error_code = Lib.create_translation_unit2(self, ast_filename, translation_unit_pointer_out)
				translation_unit_from_error_code(error_code, ast_filename, translation_unit_pointer_out)
			end
			
			# Create a translation unit directly from source and compiler arguments.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def create_translation_unit_from_source_file(source_file, command_line_args = nil, unsaved = [])
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				
				translation_unit_pointer = Lib.create_translation_unit_from_source_file(self, source_file, command_line_args.length, args_pointer, unsaved.length, unsaved_files)
				raise Error, "error parsing #{source_file.inspect}" if translation_unit_pointer.null?
				
				TranslationUnit.new translation_unit_pointer, self
			end
			
			# Create a reusable indexing action for this index.
			# @returns [IndexAction] The created index action.
			def create_action
				IndexAction.new(self)
			end
			
			# Index a source file using a temporary index action.
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			def index_source_file(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				create_action.index_source_file(source_file, command_line_args, unsaved, index_opts, translation_unit_opts, &block)
			end
			
			# Index a source file using a full compiler command line and a temporary index action.
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Full compiler arguments including argv[0].
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			def index_source_file_with_invocation(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				create_action.index_source_file_with_invocation(source_file, command_line_args, unsaved, index_opts, translation_unit_opts, &block)
			end
			
			# Index an existing translation unit using a temporary index action.
			# @parameter translation_unit [TranslationUnit] The translation unit to index.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The translation unit, or nil if indexing was aborted.
			def index_translation_unit(translation_unit, index_opts = [], &block)
				return to_enum(__method__, translation_unit, index_opts) unless block_given?
				
				create_action.index_translation_unit(translation_unit, index_opts, &block)
			end
			
			private
			
			# Parse a translation unit through a specific libclang entry point.
			# @parameter function_name [Symbol] The low-level parse function to invoke.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit_with(function_name, source_file, command_line_args, unsaved, opts)
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				translation_unit_pointer_out = FFI::MemoryPointer.new(:pointer)
				
				error_code = Lib.send(function_name, self, source_file, args_pointer, command_line_args.size, unsaved_files, unsaved.length, translation_unit_options_bitmask_from(opts), translation_unit_pointer_out)
				translation_unit_from_error_code(error_code, source_file, translation_unit_pointer_out)
			end
			
			# Build a translation unit from a libclang error code and output pointer.
			# @parameter error_code [Symbol] The libclang error code.
			# @parameter source_file [String] The path that was being parsed or loaded.
			# @parameter translation_unit_pointer_out [FFI::MemoryPointer] The output pointer for the translation unit.
			# @returns [TranslationUnit] The created translation unit.
			# @raises [Error] If the low-level call fails.
			def translation_unit_from_error_code(error_code, source_file, translation_unit_pointer_out)
				if error_code != :cx_error_success
					raise(Error, "Error parsing file. Code: #{error_code}. File: #{source_file.inspect}")
				end
				
				translation_unit_pointer = translation_unit_pointer_out.read_pointer
				TranslationUnit.new translation_unit_pointer, self
			end
		end
	end
end
