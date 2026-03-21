# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "cursor"
require_relative "diagnostic"
require_relative "file"
require_relative "source_location"
require_relative "translation_unit"

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXIdxClientFile
			typedef :pointer, :CXIdxClientEntity
			typedef :pointer, :CXIdxClientContainer
			typedef :pointer, :CXIdxClientASTFile
			typedef :pointer, :CXIndexAction
			typedef :pointer, :CXModule
			
			# @private
			class CXIdxLoc < FFI::Struct
				layout(
					:ptr_data, [:pointer, 2],
					:int_data, :uint
				)
			end
			
			# @private
			class CXIdxIncludedFileInfo < FFI::Struct
				layout(
					:hash_loc, CXIdxLoc,
					:filename, :pointer,
					:file, :CXFile,
					:is_import, :int,
					:is_angled, :int,
					:is_module_import, :int
				)
			end
			
			# @private
			class CXIdxImportedASTFileInfo < FFI::Struct
				layout(
					:file, :CXFile,
					:module, :CXModule,
					:loc, CXIdxLoc,
					:is_implicit, :int
				)
			end
			
			IdxEntityKind = enum :idx_entity_kind, [
				:unexposed, 0,
				:typedef, 1,
				:function, 2,
				:variable, 3,
				:field, 4,
				:enum_constant, 5,
				:objc_class, 6,
				:objc_protocol, 7,
				:objc_category, 8,
				:objc_instance_method, 9,
				:objc_class_method, 10,
				:objc_property, 11,
				:objc_ivar, 12,
				:enum, 13,
				:struct, 14,
				:union, 15,
				:cxx_class, 16,
				:cxx_namespace, 17,
				:cxx_namespace_alias, 18,
				:cxx_static_variable, 19,
				:cxx_static_method, 20,
				:cxx_instance_method, 21,
				:cxx_constructor, 22,
				:cxx_destructor, 23,
				:cxx_conversion_function, 24,
				:cxx_type_alias, 25,
				:cxx_interface, 26,
				:cxx_concept, 27
			]
			
			IdxEntityLanguage = enum :idx_entity_language, [
				:none, 0,
				:c, 1,
				:objc, 2,
				:cxx, 3,
				:swift, 4
			]
			
			IdxEntityCXXTemplateKind = enum :idx_entity_cxx_template_kind, [
				:non_template, 0,
				:template, 1,
				:template_partial_specialization, 2,
				:template_specialization, 3
			]
			
			IdxAttrKind = enum :idx_attr_kind, [
				:unexposed, 0,
				:ib_action, 1,
				:ib_outlet, 2,
				:ib_outlet_collection, 3
			]
			
			# @private
			class CXIdxAttrInfo < FFI::Struct
				layout(
					:kind, :idx_attr_kind,
					:cursor, CXCursor,
					:loc, CXIdxLoc
				)
			end
			
			# @private
			class CXIdxEntityInfo < FFI::Struct
				layout(
					:kind, :idx_entity_kind,
					:template_kind, :idx_entity_cxx_template_kind,
					:language, :idx_entity_language,
					:name, :pointer,
					:usr, :pointer,
					:cursor, CXCursor,
					:attributes, :pointer,
					:num_attributes, :uint
				)
			end
			
			# @private
			class CXIdxContainerInfo < FFI::Struct
				layout(
					:cursor, CXCursor
				)
			end
			
			# @private
			class CXIdxIBOutletCollectionAttrInfo < FFI::Struct
				layout(
					:attr_info, :pointer,
					:objc_class, :pointer,
					:class_cursor, CXCursor,
					:class_loc, CXIdxLoc
				)
			end
			
			IdxDeclInfoFlags = enum :idx_decl_info_flags, [
				:skipped, 0x1
			]
			
			# @private
			class CXIdxDeclInfo < FFI::Struct
				layout(
					:entity_info, :pointer,
					:cursor, CXCursor,
					:loc, CXIdxLoc,
					:semantic_container, :pointer,
					:lexical_container, :pointer,
					:is_redeclaration, :int,
					:is_definition, :int,
					:is_container, :int,
					:decl_as_container, :pointer,
					:is_implicit, :int,
					:attributes, :pointer,
					:num_attributes, :uint,
					:flags, :uint
				)
			end
			
			IdxObjCContainerKind = enum :idx_objc_container_kind, [
				:forward_ref, 0,
				:interface, 1,
				:implementation, 2
			]
			
			# @private
			class CXIdxObjCContainerDeclInfo < FFI::Struct
				layout(
					:decl_info, :pointer,
					:kind, :idx_objc_container_kind
				)
			end
			
			# @private
			class CXIdxBaseClassInfo < FFI::Struct
				layout(
					:base, :pointer,
					:cursor, CXCursor,
					:loc, CXIdxLoc
				)
			end
			
			# @private
			class CXIdxObjCProtocolRefInfo < FFI::Struct
				layout(
					:protocol, :pointer,
					:cursor, CXCursor,
					:loc, CXIdxLoc
				)
			end
			
			# @private
			class CXIdxObjCProtocolRefListInfo < FFI::Struct
				layout(
					:protocols, :pointer,
					:num_protocols, :uint
				)
			end
			
			# @private
			class CXIdxObjCInterfaceDeclInfo < FFI::Struct
				layout(
					:container_info, :pointer,
					:super_info, :pointer,
					:protocols, :pointer
				)
			end
			
			# @private
			class CXIdxObjCCategoryDeclInfo < FFI::Struct
				layout(
					:container_info, :pointer,
					:objc_class, :pointer,
					:class_cursor, CXCursor,
					:class_loc, CXIdxLoc,
					:protocols, :pointer
				)
			end
			
			# @private
			class CXIdxObjCPropertyDeclInfo < FFI::Struct
				layout(
					:decl_info, :pointer,
					:getter, :pointer,
					:setter, :pointer
				)
			end
			
			# @private
			class CXIdxCXXClassDeclInfo < FFI::Struct
				layout(
					:decl_info, :pointer,
					:bases, :pointer,
					:num_bases, :uint
				)
			end
			
			IdxEntityRefKind = enum :idx_entity_ref_kind, [
				:direct, 1,
				:implicit, 2
			]
			
			SymbolRole = enum :symbol_role, [
				:none, 0,
				:declaration, 1 << 0,
				:definition, 1 << 1,
				:reference, 1 << 2,
				:read, 1 << 3,
				:write, 1 << 4,
				:call, 1 << 5,
				:dynamic, 1 << 6,
				:address_of, 1 << 7,
				:implicit, 1 << 8
			]
			
			# @private
			class CXIdxEntityRefInfo < FFI::Struct
				layout(
					:kind, :idx_entity_ref_kind,
					:cursor, CXCursor,
					:loc, CXIdxLoc,
					:referenced_entity, :pointer,
					:parent_entity, :pointer,
					:container, :pointer,
					:role, :uint
				)
			end
			
			# @private
			class IndexerCallbacks < FFI::Struct
				layout(
					:abort_query, callback([:pointer, :pointer], :int),
					:diagnostic, callback([:pointer, :CXDiagnosticSet, :pointer], :void),
					:entered_main_file, callback([:pointer, :CXFile, :pointer], :CXIdxClientFile),
					:pp_included_file, callback([:pointer, :pointer], :CXIdxClientFile),
					:imported_ast_file, callback([:pointer, :pointer], :CXIdxClientASTFile),
					:started_translation_unit, callback([:pointer, :pointer], :CXIdxClientContainer),
					:index_declaration, callback([:pointer, :pointer], :void),
					:index_entity_reference, callback([:pointer, :pointer], :void)
				)
			end
			
			IndexOptFlags = enum [
				:none, 0x0,
				:suppress_redundant_refs, 0x1,
				:index_function_local_symbols, 0x2,
				:index_implicit_template_instantiations, 0x4,
				:suppress_warnings, 0x8,
				:skip_parsed_bodies_in_session, 0x10
			]
			
			callback :thread_function, [:pointer], :void
			
			attach_function :index_get_cxx_class_decl_info, :clang_index_getCXXClassDeclInfo, [CXIdxDeclInfo.by_ref], CXIdxCXXClassDeclInfo.by_ref
			attach_function :index_get_client_container, :clang_index_getClientContainer, [CXIdxContainerInfo.by_ref], :CXIdxClientContainer
			attach_function :index_set_client_container, :clang_index_setClientContainer, [CXIdxContainerInfo.by_ref, :CXIdxClientContainer], :void
			attach_function :index_get_client_entity, :clang_index_getClientEntity, [CXIdxEntityInfo.by_ref], :CXIdxClientEntity
			attach_function :index_set_client_entity, :clang_index_setClientEntity, [CXIdxEntityInfo.by_ref, :CXIdxClientEntity], :void
			attach_function :create_index_action, :clang_IndexAction_create, [:CXIndex], :CXIndexAction
			attach_function :dispose_index_action, :clang_IndexAction_dispose, [:CXIndexAction], :void
			attach_function :index_source_file, :clang_indexSourceFile, [:CXIndexAction, :pointer, IndexerCallbacks.by_ref, :uint, :uint, :string, :pointer, :int, :pointer, :uint, :pointer, :uint], ErrorCodes
			attach_function :index_source_file_full_argv, :clang_indexSourceFileFullArgv, [:CXIndexAction, :pointer, IndexerCallbacks.by_ref, :uint, :uint, :string, :pointer, :int, :pointer, :uint, :pointer, :uint], ErrorCodes
			attach_function :index_translation_unit, :clang_indexTranslationUnit, [:CXIndexAction, :pointer, IndexerCallbacks.by_ref, :uint, :uint, :CXTranslationUnit], ErrorCodes
			attach_function :index_loc_get_file_location, :clang_indexLoc_getFileLocation, [CXIdxLoc.by_value, :pointer, :pointer, :pointer, :pointer, :pointer], :void
			attach_function :index_loc_get_source_location, :clang_indexLoc_getCXSourceLocation, [CXIdxLoc.by_value], CXSourceLocation.by_value
			attach_function :enable_stack_traces, :clang_enableStackTraces, [], :void
			attach_function :execute_on_thread, :clang_executeOnThread, [:thread_function, :pointer, :uint], :void
			attach_function :toggle_crash_recovery, :clang_toggleCrashRecovery, [:uint], :void
		end
	end
end
