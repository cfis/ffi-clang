# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/string"

module FFI
	module Clang
		# Represents a set of strings returned by libclang.
		class StringSet
			include Enumerable
			
			# @attribute [r] size
			# 	@returns [Integer] The number of strings in the set.
			attr_reader :size
			
			# Initialize a string set from a CXStringSet pointer.
			# @parameter string_set [Lib::CXStringSet | FFI::Pointer | Nil] The CXStringSet to extract.
			def initialize(string_set)
				@strings = []
				@size = 0
				
				return if string_set.nil?
				
				string_set = Lib::CXStringSet.new(string_set) if string_set.is_a?(FFI::Pointer)
				return if string_set.pointer.null?
				
				begin
					@size = string_set[:count]
					strings = string_set[:strings]
					return if strings.null?
					
					@size.times do |i|
						@strings << Lib.get_string(Lib::CXString.new(strings + (i * Lib::CXString.size)))
					end
				ensure
					Lib.dispose_string_set(string_set)
				end
			end
			
			# Iterate over each string.
			# @yields {|string| ...} Each string in the set.
			# 	@parameter string [String] The extracted string.
			# @returns [Enumerator] If no block is given.
			def each(&block)
				return to_enum(__method__) unless block_given?
				
				@strings.each(&block)
				
				self
			end
		end
	end
end
