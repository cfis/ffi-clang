# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# Shared helpers for preparing libclang invocation arguments and options.
		module InvocationSupport
			private
			
			# Convert command line arguments to a pointer array for libclang.
			# @parameter command_line_args [Array(String)] The command line arguments.
			# @returns [Array(FFI::MemoryPointer, Array(FFI::MemoryPointer))] The pointer array and string buffers that back it.
			def args_pointer_from(command_line_args)
				args_pointer = MemoryPointer.new(:pointer, command_line_args.length)
				
				strings = command_line_args.map do |arg|
					MemoryPointer.from_string(arg.to_s)
				end
				
				args_pointer.put_array_of_pointer(0, strings) unless strings.empty?
				return args_pointer, strings
			end
			
			# Normalize command line arguments and inject libclang support flags.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @returns [Array(String)] The normalized compiler arguments.
			def normalized_command_line_args(command_line_args)
				command_line_args = Array(command_line_args)
				
				# Inject -resource-dir if libclang can't find it on its own:
				command_line_args + Lib.args.command_line_args(command_line_args)
			end
			
			# Convert translation unit options to a bitmask.
			# @parameter opts [Array(Symbol)] The translation unit options.
			# @returns [Integer] The resulting bitmask.
			def translation_unit_options_bitmask_from(opts)
				Lib.bitmask_from(Lib::TranslationUnitFlags, opts)
			end
		end
	end
end
