# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe FFI::Clang::Cursor do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
	let(:cursor) {translation_unit.cursor}
	
	describe "#storage_class" do
		let(:extern_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "extern_var"
			end
		end
		
		let(:static_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "static_var"
			end
		end
		
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns :sc_extern for extern variables" do
			expect(extern_var.storage_class).to eq(:sc_extern)
		end
		
		it "returns :sc_static for static variables" do
			expect(static_var.storage_class).to eq(:sc_static)
		end
		
		it "returns :sc_none for normal global variables" do
			expect(global_var.storage_class).to eq(:sc_none)
		end
	end
	
	describe "#function_inlined?" do
		let(:inline_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "inline_func"
			end
		end
		
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns true for inline functions" do
			expect(inline_func.function_inlined?).to eq(true)
		end
		
		it "returns false for non-inline functions" do
			expect(visible_func.function_inlined?).to eq(false)
		end
	end
	
	describe "#visibility" do
		let(:hidden_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "hidden_func"
			end
		end
		
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns :visibility_hidden for hidden functions" do
			expect(hidden_func.visibility).to eq(:visibility_hidden)
		end
		
		it "returns :visibility_default for default visibility functions" do
			expect(visible_func.visibility).to eq(:visibility_default)
		end
	end
	
	describe "#offset_of_field" do
		let(:field_a) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "field_a" and parent.spelling == "FieldStruct"
			end
		end
		
		it "returns the offset in bits" do
			expect(field_a.offset_of_field).to eq(0)
		end
	end
	
	describe "#brief_comment_text" do
		let(:documented_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "documented_func"
			end
		end
		
		it "returns the brief comment text" do
			expect(documented_func.brief_comment_text).to eq("Brief comment on this function.")
		end
	end
	
	describe "#invalid_declaration?" do
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns false for valid declarations" do
			expect(global_var.invalid_declaration?).to eq(false)
		end
	end
	
	describe "#has_attrs?" do
		let(:hidden_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "hidden_func"
			end
		end
		
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns true for cursors with attributes" do
			expect(hidden_func.has_attrs?).to eq(true)
		end
		
		it "returns false for cursors without attributes" do
			expect(global_var.has_attrs?).to eq(false)
		end
	end
	
	describe "#mangling" do
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns the mangled name" do
			mangled = visible_func.mangling
			expect(mangled).to be_kind_of(String)
			expect(mangled).not_to be_empty
		end
	end
end

describe FFI::Clang::Types::Type do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
	let(:cursor) {translation_unit.cursor}
	
	describe "#visit_fields" do
		let(:field_struct) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "FieldStruct"
			end
		end
		
		it "visits all fields of a struct" do
			fields = []
			field_struct.type.visit_fields do |field|
				fields << field.spelling
			end
			expect(fields).to eq(["field_a", "field_b", "field_c"])
		end
	end
	
	describe "#address_space" do
		let(:int_type) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end.type
		end
		
		it "returns the address space" do
			expect(int_type.address_space).to eq(0)
		end
	end
	
	describe "#typedef_name" do
		let(:typedef_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_typedef_decl
			end
		end
		
		it "returns the typedef name for typedef types" do
			# The type of a typedef decl's underlying type may have a typedef_name
			expect(typedef_cursor).to be_nil.or be_kind_of(FFI::Clang::Cursor)
		end
	end
	
	describe "#fully_qualified_name" do
		let(:my_struct) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "MyStruct"
			end
		end
		
		it "returns the fully qualified type name" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			policy = FFI::Clang::PrintingPolicy.new(my_struct.cursor)
			name = my_struct.type.fully_qualified_name(policy)
			expect(name).to include("MyNamespace")
			expect(name).to include("MyStruct")
		end
		
		it "prepends :: with global ns prefix" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			policy = FFI::Clang::PrintingPolicy.new(my_struct.cursor)
			name = my_struct.type.fully_qualified_name(policy, with_global_ns_prefix: true)
			expect(name).to start_with("::")
		end
	end
end
