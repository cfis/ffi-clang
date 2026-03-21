# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/indexing"
require_relative "cursor"
require_relative "file"
require_relative "source_location"
require_relative "translation_unit"
require_relative "invocation_support"
require_relative "unsaved_file"
require_relative "error"

module FFI
	module Clang
		# Represents a reusable libclang indexing session.
		class IndexAction < AutoPointer
			include InvocationSupport
			
			# Represents a diagnostic snapshot emitted during indexing.
			class Diagnostic
				# @attribute [r] severity
				# 	@returns [Symbol] The diagnostic severity.
				# @attribute [r] spelling
				# 	@returns [String] The diagnostic text.
				# @attribute [r] location
				# 	@returns [ExpansionLocation] The diagnostic location.
				attr_reader :severity, :spelling, :location
				
				# Build a diagnostic snapshot from a libclang diagnostic pointer.
				# @parameter pointer [FFI::Pointer] The libclang diagnostic pointer.
				def initialize(pointer)
					@severity = Lib.get_diagnostic_severity(pointer)
					@spelling = Lib.extract_string(Lib.get_diagnostic_spelling(pointer))
					@location = ExpansionLocation.new(Lib.get_diagnostic_location(pointer))
				end
			end
			
			# Represents an entity container reported by the indexing API.
			class Container
				# @attribute [r] cursor
				# 	@returns [Cursor] The cursor describing the container.
				attr_reader :cursor
				
				# Build a container wrapper from a libclang container info pointer.
				# @parameter info [Lib::CXIdxContainerInfo] The low-level container info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived cursors.
				def initialize(info, translation_unit)
					@cursor = Cursor.new(info[:cursor], translation_unit)
				end
			end
			
			# Represents an indexed entity.
			class Entity
				# @attribute [r] kind
				# 	@returns [Symbol] The entity kind.
				# @attribute [r] template_kind
				# 	@returns [Symbol] The C++ template kind.
				# @attribute [r] language
				# 	@returns [Symbol] The source language.
				# @attribute [r] name
				# 	@returns [String | Nil] The entity name.
				# @attribute [r] usr
				# 	@returns [String | Nil] The unified symbol resolution string.
				# @attribute [r] cursor
				# 	@returns [Cursor] The cursor describing the entity.
				attr_reader :kind, :template_kind, :language, :name, :usr, :cursor
				
				# Build an entity wrapper from a libclang entity info pointer.
				# @parameter info [Lib::CXIdxEntityInfo] The low-level entity info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived cursors.
				def initialize(info, translation_unit)
					@kind = info[:kind]
					@template_kind = info[:template_kind]
					@language = info[:language]
					@name = self.class.string_from_pointer(info[:name])
					@usr = self.class.string_from_pointer(info[:usr])
					@cursor = Cursor.new(info[:cursor], translation_unit)
				end
				
				# @private
				def self.string_from_pointer(pointer)
					return nil if pointer.null?
					
					pointer.read_string
				end
			end
			
			# Represents an include directive encountered during indexing.
			class IncludedFile
				# @attribute [r] filename
				# 	@returns [String] The file name as written in the include directive.
				# @attribute [r] file
				# 	@returns [File | Nil] The resolved included file.
				# @attribute [r] location
				# 	@returns [ExpansionLocation] The location of the include directive.
				attr_reader :filename, :file, :location
				
				# Build an include wrapper from a libclang include info pointer.
				# @parameter info [Lib::CXIdxIncludedFileInfo] The low-level include info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived wrappers.
				def initialize(info, translation_unit)
					@filename = Entity.string_from_pointer(info[:filename])
					@file = self.class.file_from_pointer(info[:file], translation_unit)
					@location = ExpansionLocation.new(Lib.index_loc_get_source_location(info[:hash_loc]))
					@import = info[:is_import] != 0
					@angled = info[:is_angled] != 0
					@module_import = info[:is_module_import] != 0
				end
				
				# Check if the directive was an import.
				# @returns [Boolean] True if the directive was an import.
				def import?
					@import
				end
				
				# Check if the include used angle brackets.
				# @returns [Boolean] True if the include used angle brackets.
				def angled?
					@angled
				end
				
				# Check if the include was converted into a module import by clang.
				# @returns [Boolean] True if the include became a module import.
				def module_import?
					@module_import
				end
				
				# @private
				def self.file_from_pointer(pointer, translation_unit)
					return nil if pointer.null?
					
					FFI::Clang::File.new(pointer, translation_unit)
				end
			end
			
			# Represents an imported AST file encountered during indexing.
			class ImportedASTFile
				# @attribute [r] file
				# 	@returns [File | Nil] The imported AST file.
				# @attribute [r] location
				# 	@returns [ExpansionLocation] The import location.
				attr_reader :file, :location
				
				# Build an imported AST file wrapper from low-level info.
				# @parameter info [Lib::CXIdxImportedASTFileInfo] The low-level import info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived wrappers.
				def initialize(info, translation_unit)
					@file = IncludedFile.file_from_pointer(info[:file], translation_unit)
					@location = ExpansionLocation.new(Lib.index_loc_get_source_location(info[:loc]))
					@implicit = info[:is_implicit] != 0
				end
				
				# Check if this import was implicit.
				# @returns [Boolean] True if the import was implicit.
				def implicit?
					@implicit
				end
			end
			
			# Represents a declaration event reported during indexing.
			class Declaration
				# @attribute [r] cursor
				# 	@returns [Cursor] The declaration cursor.
				# @attribute [r] location
				# 	@returns [ExpansionLocation] The declaration location.
				# @attribute [r] entity
				# 	@returns [Entity | Nil] The declared entity.
				# @attribute [r] semantic_container
				# 	@returns [Container | Nil] The semantic container.
				# @attribute [r] lexical_container
				# 	@returns [Container | Nil] The lexical container.
				# @attribute [r] declaration_container
				# 	@returns [Container | Nil] The declaration container if this declaration is also a container.
				# @attribute [r] flags
				# 	@returns [Array(Symbol)] The declaration flags.
				attr_reader :cursor, :location, :entity, :semantic_container, :lexical_container, :declaration_container, :flags
				
				# Build a declaration wrapper from low-level info.
				# @parameter info [Lib::CXIdxDeclInfo] The low-level declaration info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived wrappers.
				def initialize(info, translation_unit)
					@cursor = Cursor.new(info[:cursor], translation_unit)
					@location = ExpansionLocation.new(Lib.index_loc_get_source_location(info[:loc]))
					@entity = self.class.entity_from_pointer(info[:entity_info], translation_unit)
					@semantic_container = self.class.container_from_pointer(info[:semantic_container], translation_unit)
					@lexical_container = self.class.container_from_pointer(info[:lexical_container], translation_unit)
					@declaration_container = self.class.container_from_pointer(info[:decl_as_container], translation_unit)
					@redeclaration = info[:is_redeclaration] != 0
					@definition = info[:is_definition] != 0
					@container = info[:is_container] != 0
					@implicit = info[:is_implicit] != 0
					@flags = Lib.opts_from(Lib::IdxDeclInfoFlags, info[:flags])
				end
				
				# Check if this declaration is a redeclaration.
				# @returns [Boolean] True if this is a redeclaration.
				def redeclaration?
					@redeclaration
				end
				
				# Check if this declaration is a definition.
				# @returns [Boolean] True if this declaration is a definition.
				def definition?
					@definition
				end
				
				# Check if this declaration is itself a container.
				# @returns [Boolean] True if this declaration introduces a container.
				def container?
					@container
				end
				
				# Check if this declaration was implicit.
				# @returns [Boolean] True if the declaration was implicit.
				def implicit?
					@implicit
				end
				
				# @private
				def self.entity_from_pointer(pointer, translation_unit)
					return nil if pointer.null?
					
					Entity.new(Lib::CXIdxEntityInfo.new(pointer), translation_unit)
				end
				
				# @private
				def self.container_from_pointer(pointer, translation_unit)
					return nil if pointer.null?
					
					Container.new(Lib::CXIdxContainerInfo.new(pointer), translation_unit)
				end
			end
			
			# Represents a reference event reported during indexing.
			class EntityReference
				# @attribute [r] kind
				# 	@returns [Symbol] The reference kind.
				# @attribute [r] cursor
				# 	@returns [Cursor] The reference cursor.
				# @attribute [r] location
				# 	@returns [ExpansionLocation] The reference location.
				# @attribute [r] referenced_entity
				# 	@returns [Entity | Nil] The entity being referenced.
				# @attribute [r] parent_entity
				# 	@returns [Entity | Nil] The logical parent entity of the reference.
				# @attribute [r] container
				# 	@returns [Container | Nil] The lexical container of the reference.
				# @attribute [r] roles
				# 	@returns [Array(Symbol)] The roles attributed to the reference.
				attr_reader :kind, :cursor, :location, :referenced_entity, :parent_entity, :container, :roles
				
				# Build a reference wrapper from low-level info.
				# @parameter info [Lib::CXIdxEntityRefInfo] The low-level reference info.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived wrappers.
				def initialize(info, translation_unit)
					@kind = info[:kind]
					@cursor = Cursor.new(info[:cursor], translation_unit)
					@location = ExpansionLocation.new(Lib.index_loc_get_source_location(info[:loc]))
					@referenced_entity = Declaration.entity_from_pointer(info[:referenced_entity], translation_unit)
					@parent_entity = Declaration.entity_from_pointer(info[:parent_entity], translation_unit)
					@container = Declaration.container_from_pointer(info[:container], translation_unit)
					@roles = Lib.opts_from(Lib::SymbolRole, info[:role])
				end
			end
			
			# Initialize an index action for the given index.
			# @parameter index [Index] The owning index.
			def initialize(index)
				super Lib.create_index_action(index)
				@index = index
			end
			
			# Release the underlying index action pointer.
			# @parameter pointer [FFI::Pointer] The pointer to release.
			def self.release(pointer)
				Lib.dispose_index_action(pointer)
			end
			
			# Index a source file and yield indexing events.
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Array(Diagnostic) | File | IncludedFile | ImportedASTFile | Declaration | EntityReference | NilClass] The event payload.
			# Event payloads:
			# - `:diagnostic` => `Array(Diagnostic)`
			# - `:entered_main_file` => `FFI::Clang::File`
			# - `:included_file` => `IncludedFile`
			# - `:imported_ast_file` => `ImportedASTFile`
			# - `:started_translation_unit` => `nil`
			# - `:declaration` => `Declaration`
			# - `:reference` => `EntityReference`
			# @returns [Enumerator] If no block is given.
			# If the block returns `:abort`, libclang stops the next time it polls `abortQuery`,
			# so a few more callbacks may be delivered before control returns.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			# @raises [Error] If libclang fails to index the source file.
			def index_source_file(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				translation_unit_pointer_out = MemoryPointer.new(:pointer)
				adapter = CallbackAdapter.new(nil, &block)
				
				error_code = Lib.index_source_file(
					self,
					nil,
					adapter.callbacks,
					adapter.callbacks.size,
					index_options_bitmask_from(index_opts),
					source_file,
					args_pointer,
					command_line_args.length,
					unsaved_files,
					unsaved.length,
					translation_unit_pointer_out,
					translation_unit_options_bitmask_from(translation_unit_opts)
				)
				
				return nil if adapter.aborted?
				
				translation_unit_from_indexing_result(error_code, source_file, translation_unit_pointer_out)
			end
			
			# Index a source file using a full compiler command line including argv[0].
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Full compiler arguments including argv[0].
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Array(Diagnostic) | File | IncludedFile | ImportedASTFile | Declaration | EntityReference | NilClass] The event payload.
			# Event payloads:
			# - `:diagnostic` => `Array(Diagnostic)`
			# - `:entered_main_file` => `FFI::Clang::File`
			# - `:included_file` => `IncludedFile`
			# - `:imported_ast_file` => `ImportedASTFile`
			# - `:started_translation_unit` => `nil`
			# - `:declaration` => `Declaration`
			# - `:reference` => `EntityReference`
			# @returns [Enumerator] If no block is given.
			# If the block returns `:abort`, libclang stops the next time it polls `abortQuery`,
			# so a few more callbacks may be delivered before control returns.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			# @raises [Error] If libclang fails to index the source file.
			def index_source_file_with_invocation(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				translation_unit_pointer_out = MemoryPointer.new(:pointer)
				adapter = CallbackAdapter.new(nil, &block)
				
				error_code = Lib.index_source_file_full_argv(
					self,
					nil,
					adapter.callbacks,
					adapter.callbacks.size,
					index_options_bitmask_from(index_opts),
					source_file,
					args_pointer,
					command_line_args.length,
					unsaved_files,
					unsaved.length,
					translation_unit_pointer_out,
					translation_unit_options_bitmask_from(translation_unit_opts)
				)
				
				return nil if adapter.aborted?
				
				translation_unit_from_indexing_result(error_code, source_file, translation_unit_pointer_out)
			end
			
			# Index an existing translation unit and yield indexing events.
			# @parameter translation_unit [TranslationUnit] The translation unit to index.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Array(Diagnostic) | File | IncludedFile | ImportedASTFile | Declaration | EntityReference | NilClass] The event payload.
			# Event payloads:
			# - `:diagnostic` => `Array(Diagnostic)`
			# - `:entered_main_file` => `FFI::Clang::File`
			# - `:included_file` => `IncludedFile`
			# - `:imported_ast_file` => `ImportedASTFile`
			# - `:started_translation_unit` => `nil`
			# - `:declaration` => `Declaration`
			# - `:reference` => `EntityReference`
			# @returns [Enumerator] If no block is given.
			# If the block returns `:abort`, libclang stops the next time it polls `abortQuery`,
			# so a few more callbacks may be delivered before control returns.
			# @returns [TranslationUnit | Nil] The translation unit, or nil if indexing was aborted.
			# @raises [Error] If libclang fails to index the translation unit.
			def index_translation_unit(translation_unit, index_opts = [], &block)
				return to_enum(__method__, translation_unit, index_opts) unless block_given?
				
				adapter = CallbackAdapter.new(translation_unit, &block)
				error_code = Lib.index_translation_unit(
					self,
					nil,
					adapter.callbacks,
					adapter.callbacks.size,
					index_options_bitmask_from(index_opts),
					translation_unit
				)
				
				return nil if adapter.aborted?
				
				raise_indexing_error(error_code, translation_unit.spelling) unless error_code == :cx_error_success
				
				translation_unit
			end
			
			private
			
			# Adapter object that owns the callback procs for a single indexing run.
			class CallbackAdapter
				# @attribute [r] callbacks
				# 	@returns [Lib::IndexerCallbacks] The callback struct passed to libclang.
				attr_reader :callbacks
				
				# Build callbacks that snapshot libclang indexing payloads.
				# @parameter translation_unit [TranslationUnit | Nil] The translation unit for derived wrappers.
				# @yields {|event, payload| ...} The user callback.
				def initialize(translation_unit, &block)
					@translation_unit = translation_unit
					@block = block
					@aborted = false
					@callbacks = Lib::IndexerCallbacks.new
					initialize_callbacks
				end
				
				# Check if indexing was aborted by the user callback.
				# @returns [Boolean] True if indexing was aborted.
				def aborted?
					@aborted
				end
				
				private
				
				# Install no-op libclang callbacks that forward snapshots to the Ruby block.
				def initialize_callbacks
					@abort_query = proc do |_client_data, _reserved|
						@aborted ? 1 : 0
					end
					
					@diagnostic = proc do |_client_data, diagnostic_set, _reserved|
						diagnostics = diagnostics_from_set(diagnostic_set)
						dispatch(:diagnostic, diagnostics)
					end
					
					@entered_main_file = proc do |_client_data, file, _reserved|
						dispatch(:entered_main_file, FFI::Clang::File.new(file, @translation_unit))
						nil
					end
					
					@pp_included_file = proc do |_client_data, info_pointer|
						info = Lib::CXIdxIncludedFileInfo.new(info_pointer)
						dispatch(:included_file, IncludedFile.new(info, @translation_unit))
						nil
					end
					
					@imported_ast_file = proc do |_client_data, info_pointer|
						info = Lib::CXIdxImportedASTFileInfo.new(info_pointer)
						dispatch(:imported_ast_file, ImportedASTFile.new(info, @translation_unit))
						nil
					end
					
					@started_translation_unit = proc do |_client_data, _reserved|
						dispatch(:started_translation_unit, nil)
						nil
					end
					
					@index_declaration = proc do |_client_data, info_pointer|
						info = Lib::CXIdxDeclInfo.new(info_pointer)
						dispatch(:declaration, Declaration.new(info, @translation_unit))
					end
					
					@index_entity_reference = proc do |_client_data, info_pointer|
						info = Lib::CXIdxEntityRefInfo.new(info_pointer)
						dispatch(:reference, EntityReference.new(info, @translation_unit))
					end
					
					@callbacks[:abort_query] = @abort_query
					@callbacks[:diagnostic] = @diagnostic
					@callbacks[:entered_main_file] = @entered_main_file
					@callbacks[:pp_included_file] = @pp_included_file
					@callbacks[:imported_ast_file] = @imported_ast_file
					@callbacks[:started_translation_unit] = @started_translation_unit
					@callbacks[:index_declaration] = @index_declaration
					@callbacks[:index_entity_reference] = @index_entity_reference
				end
				
				# Snapshot diagnostics from a diagnostic set.
				# @parameter diagnostic_set [FFI::Pointer] The diagnostic set pointer.
				# @returns [Array(Diagnostic)] Diagnostic snapshots.
				def diagnostics_from_set(diagnostic_set)
					Lib.get_num_diagnostics_in_set(diagnostic_set).times.map do |i|
						Diagnostic.new(Lib.get_diagnostic_in_set(diagnostic_set, i))
					end
				end
				
				# Dispatch an event to the Ruby block.
				# @parameter event [Symbol] The event type.
				# @parameter payload [Object] The event payload.
				def dispatch(event, payload)
					result = @block.call(event, payload)
					@aborted = true if result == :abort
				end
			end
			
			# Convert indexing options to a bitmask.
			# @parameter opts [Array(Symbol)] The indexing options.
			# @returns [Integer] The resulting bitmask.
			def index_options_bitmask_from(opts)
				Lib.bitmask_from(Lib::IndexOptFlags, opts)
			end
			
			# Build a translation unit from the result of an indexing call.
			# @parameter error_code [Symbol | Integer] The libclang error code.
			# @parameter source_file [String] The indexed source file.
			# @parameter translation_unit_pointer_out [FFI::MemoryPointer] The output pointer for the translation unit.
			# @returns [TranslationUnit] The resulting translation unit.
			# @raises [Error] If indexing failed.
			def translation_unit_from_indexing_result(error_code, source_file, translation_unit_pointer_out)
				raise_indexing_error(error_code, source_file) unless error_code == :cx_error_success
				
				translation_unit_pointer = translation_unit_pointer_out.read_pointer
				raise Error, "error indexing #{source_file.inspect}" if translation_unit_pointer.null?
				
				TranslationUnit.new(translation_unit_pointer, @index)
			end
			
			# Raise a Ruby error for a libclang indexing failure.
			# @parameter error_code [Symbol | Integer] The libclang error code.
			# @parameter source [String] The source path or translation unit spelling.
			# @raises [Error] Always raises.
			def raise_indexing_error(error_code, source)
				error_name = error_code.is_a?(Symbol) ? error_code : Lib::ErrorCodes.find(error_code)
				raise Error, "error indexing #{source.inspect}: #{error_name || error_code}"
			end
		end
	end
end
