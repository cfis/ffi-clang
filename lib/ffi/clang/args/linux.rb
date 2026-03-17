# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# Linux-specific clang configuration.
		class LinuxArgs < Args
			private
			
			def find_libclang_paths
				if llvm_library_dir
					return [::File.join(llvm_library_dir, "libclang.so")]
				end
				
				["clang"]
			end
		end
	end
end
