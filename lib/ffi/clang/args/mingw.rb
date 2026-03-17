# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# MinGW/MSYS2-specific clang configuration.
		class MingwArgs < Args
			private
			
			def find_libclang_paths
				if llvm_bin_dir
					return [::File.join(llvm_bin_dir, "libclang.dll")]
				end
				
				["libclang.dll"]
			end
		end
	end
end
