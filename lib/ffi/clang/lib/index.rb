# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2024, by Charlie Savage.

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXIndex
			
			# Source code index:
			attach_function :create_index, :clang_createIndex, [:int, :int], :CXIndex
			attach_function :dispose_index, :clang_disposeIndex, [:CXIndex], :void
			
			if Clang.clang_version >= Gem::Version.new("17.0.0")
				CXChoice = enum(FFI::Type::UINT8, [
					:default, 0,
					:enabled, 1,
					:disabled, 2
				])

				# FFI struct for index creation options (libclang 17.0.0+).
				#
				# The C struct uses bitfields for ExcludeDeclarationsFromPCH (bit 0),
				# DisplayDiagnostics (bit 1), and StorePreamblesInMemory (bit 2).
				# FFI doesn't support bitfields, so these are packed into a single :ushort.
				# Use the helper methods to set them.
				class CXIndexOptions < FFI::Struct
					layout(
						:size, :uint,
						:thread_background_priority_for_indexing, CXChoice,
						:thread_background_priority_for_editing, CXChoice,
						:bitfields, :ushort,
						:preamble_storage_path, :pointer,
						:invocation_emission_path, :pointer
					)

					# Create a new CXIndexOptions with size pre-populated.
					def initialize(*args)
						super
						self[:size] = self.class.size
					end

					# Set whether to exclude declarations from PCH.
					# @parameter value [Boolean] True to exclude.
					def exclude_declarations_from_pch=(value)
						set_bitfield(0, value)
					end

					# Set whether to display diagnostics.
					# @parameter value [Boolean] True to display.
					def display_diagnostics=(value)
						set_bitfield(1, value)
					end

					# Set whether to store preambles in memory.
					# @parameter value [Boolean] True to store in memory.
					def store_preambles_in_memory=(value)
						set_bitfield(2, value)
					end

					private

					# Set a single bit in the bitfields.
					# @parameter bit [Integer] The bit position.
					# @parameter value [Boolean] The value to set.
					def set_bitfield(bit, value)
						if value
							self[:bitfields] |= (1 << bit)
						else
							self[:bitfields] &= ~(1 << bit)
						end
					end
				end
				
				attach_function :create_index_with_options, :clang_createIndexWithOptions, [CXIndexOptions.by_ref], :CXIndex
			end
		end
	end
end
