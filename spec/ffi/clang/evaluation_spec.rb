# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe FFI::Clang::EvalResult do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("eval.c"))}
	let(:cursor) {translation_unit.cursor}
	
	describe "#evaluate" do
		let(:const_int) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "const_int"
			end
		end
		
		let(:const_double) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "const_double"
			end
		end
		
		let(:const_str) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "const_str"
			end
		end
		
		it "returns nil for a non-evaluatable cursor" do
			result = cursor.evaluate
			expect(result).to be_nil
		end
		
		it "evaluates an integer constant" do
			result = const_int.evaluate
			expect(result).to be_kind_of(FFI::Clang::EvalResult)
			expect(result.kind).to eq(:int)
			expect(result.as_int).to eq(10)
		end
		
		it "returns the result as a long long" do
			result = const_int.evaluate
			expect(result.as_long_long).to eq(10)
		end
		
		it "checks if the result is unsigned" do
			result = const_int.evaluate
			expect(result.unsigned_int?).to eq(false)
		end
		
		it "evaluates a floating-point constant" do
			result = const_double.evaluate
			expect(result).to be_kind_of(FFI::Clang::EvalResult)
			expect(result.kind).to eq(:float)
			expect(result.as_double).to be_within(0.001).of(3.14)
		end
		
		it "evaluates a string constant" do
			result = const_str.evaluate
			expect(result).to be_kind_of(FFI::Clang::EvalResult)
			expect(result.kind).to eq(:str_literal)
			expect(result.as_str).to eq("hello")
		end
	end
end
