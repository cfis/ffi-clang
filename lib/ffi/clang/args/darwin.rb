# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# macOS-specific clang configuration using Xcode toolchain paths.
		class DarwinArgs < Args
			private
			
			def find_libclang_paths
				if llvm_library_dir
					return [::File.join(llvm_library_dir, "libclang.dylib")]
				end
				
				# Try xcode-select paths.
				begin
					xcode_dir = `xcode-select -p`.chomp
					%W[
						#{xcode_dir}/Toolchains/XcodeDefault.xctoolchain/usr/lib/libclang.dylib
						#{xcode_dir}/usr/lib/libclang.dylib
					].each do |f|
						return [f] if ::File.exist?(f)
					end
				rescue Errno::ENOENT
					# xcode-select not available
				end
				
				["clang"]
			end
			
			def isysroot
				if defined?(@isysroot)
					return @isysroot
				end
				
				@isysroot = begin
					stdout, _stderr, status = Open3.capture3("xcrun", "--show-sdk-path")
					status.success? ? stdout.strip : nil
				rescue Errno::ENOENT
					nil
				end
			end
			
			def extra_args(command_line_args)
				args = []
				
				if !command_line_args.include?("-isysroot") && isysroot
					args.push("-isysroot", isysroot)
				end
				
				args
			end
		end
	end
end
