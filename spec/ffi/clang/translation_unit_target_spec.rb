# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe FFI::Clang::TranslationUnit do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("a.c"))}
	
	describe "#target_triple" do
		it "returns the target triple string" do
			triple = translation_unit.target_triple
			expect(triple).to be_kind_of(String)
			expect(triple).not_to be_empty
		end
	end
	
	describe "#target_pointer_width" do
		it "returns the pointer width in bits" do
			width = translation_unit.target_pointer_width
			expect(width).to be_kind_of(Integer)
			expect([32, 64]).to include(width)
		end
	end
end
