# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe "Index bindings" do
	before :all do
		FileUtils.mkdir_p TMP_DIR
	end
	
	after :all do
		FileUtils.rm_rf TMP_DIR
	end
	
	it "exposes skipped-range bindings" do
		expect(FFI::Clang::Lib).to respond_to(:get_skipped_ranges)
		expect(FFI::Clang::Lib).to respond_to(:get_all_skipped_ranges)
	end
	
	it "stores CXIndexOptions choice and string fields" do
		skip "CXIndexOptions unavailable" unless defined?(FFI::Clang::Lib::CXIndexOptions)
		
		options = FFI::Clang::Lib::CXIndexOptions.new
		options.thread_background_priority_for_indexing = :enabled
		options.thread_background_priority_for_editing = :disabled
		options.preamble_storage_path = TMP_DIR
		options.invocation_emission_path = TMP_DIR
		
		expect(options[:thread_background_priority_for_indexing]).to eq(:enabled)
		expect(options[:thread_background_priority_for_editing]).to eq(:disabled)
		expect(options[:preamble_storage_path].read_string).to eq(TMP_DIR)
		expect(options[:invocation_emission_path].read_string).to eq(TMP_DIR)
	end
	
	it "applies CXIndexOptions priority settings to the created index" do
		skip "CXIndexOptions unavailable" unless defined?(FFI::Clang::Lib::CXIndexOptions)
		
		options = FFI::Clang::Lib::CXIndexOptions.new
		options.thread_background_priority_for_indexing = :enabled
		options.thread_background_priority_for_editing = :enabled
		
		index = Index.create_with_options(options)
		bitmask = FFI::Clang::Lib.get_global_options(index)
		flags = FFI::Clang::Lib.opts_from(FFI::Clang::Lib::GlobalOptFlags, bitmask)
		
		expect(flags).to include(:thread_background_priority_for_indexing)
		expect(flags).to include(:thread_background_priority_for_editing)
	end
	
	it "defines the IndexerCallbacks ABI and index action bindings" do
		skip "indexing callbacks unavailable" unless FFI::Clang::Lib.respond_to?(:create_index_action)
		
		expect(FFI::Clang::Lib::IndexerCallbacks.size).to eq(FFI.type_size(:pointer) * 8)
		expect(FFI::Clang::Lib::IndexOptFlags[:skip_parsed_bodies_in_session]).to eq(0x10)
		
		index = Index.new
		action = FFI::Clang::Lib.create_index_action(index)
		expect(action).not_to be_null
		FFI::Clang::Lib.dispose_index_action(action)
	end
	
	it "stores entity reference roles as integer bitmasks" do
		info = FFI::Clang::Lib::CXIdxEntityRefInfo.new
		info[:role] = FFI::Clang::Lib.bitmask_from(FFI::Clang::Lib::SymbolRole, [:reference])
		
		expect(info[:role]).to eq(4)
	end
end
