# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require "open3"

module FFI
	module Clang
		# Locates the clang resource directory containing compiler-intrinsic
		# headers (stddef.h, stdarg.h, etc.). libclang computes this relative
		# to its own shared library path, which fails on some platforms (e.g.
		# Fedora's lib64 layout, MSVC-bundled clang on Windows).
		class ClangResource
			# Initialize with hints for finding the resource directory.
			# Discovery is deferred until actually needed.
			# @parameter libclang_path [String | Nil] Path to the loaded libclang shared library.
			# @parameter llvm_config [String | Nil] Path to the llvm-config binary.
			def initialize(libclang_path: nil, llvm_config: nil)
				@libclang_path = libclang_path
				@llvm_config = llvm_config
			end
			
			# Return the resource directory command line args, taking into account
			# any existing args that may already include -resource-dir.
			# @parameter command_line_args [Array(String)] The existing command line arguments.
			# @returns [Array(String)] The -resource-dir args to append, or empty if not needed.
			def command_line_args(command_line_args = [])
				if !command_line_args.include?("-resource-dir") && path
					["-resource-dir", path]
				else
					[]
				end
			end
			
			# The resolved resource directory path.
			# @returns [String | Nil] The resource directory path, or nil if not found.
			def path
				if defined?(@path)
					@path
				else
					@path = find
				end
			end
			
			private
			
			# Find the clang resource directory using multiple strategies.
			# @returns [String | Nil] The resource directory path, or nil if not found.
			def find
				# 1. Explicit override via environment variable.
				env = ENV["LIBCLANG_RESOURCE_DIR"]
				return env if valid_resource_dir?(env)
				
				# 2. Clang binary from llvm-config.
				if @llvm_config
					clang_path = ::File.join(`#{@llvm_config} --bindir`.chomp, "clang")
					if (dir = resource_dir_from_clang(clang_path))
						return dir
					end
				end
				
				# 3. clang on PATH.
				if (dir = resource_dir_from_clang("clang"))
					return dir
				end
				
				# 4. Probe relative to the loaded libclang shared library.
				if @libclang_path && (dir = probe_from_libclang(@libclang_path))
					return dir
				end
				
				nil
			end
			
			# Ask a clang binary for its resource directory.
			# @parameter clang [String] Path to or name of the clang binary.
			# @returns [String | Nil] The resource directory path, or nil if not found.
			def resource_dir_from_clang(clang)
				stdout, _stderr, status = Open3.capture3(clang, "-print-resource-dir")
				return nil unless status.success?
				
				dir = stdout.strip
				valid_resource_dir?(dir) ? dir : nil
			rescue Errno::ENOENT
				nil
			end
			
			# Probe for the resource directory relative to the libclang shared library.
			# @parameter libclang_path [String] Path to the libclang shared library.
			# @returns [String | Nil] The resource directory path, or nil if not found.
			def probe_from_libclang(libclang_path)
				base = ::File.expand_path(::File.dirname(libclang_path))
				
				candidates = []
				candidates.concat Dir.glob(::File.join(base, "..", "lib", "clang", "*"))
				candidates.concat Dir.glob(::File.join(base, "..", "..", "lib", "clang", "*"))
				candidates.concat Dir.glob(::File.join(base, "clang", "*"))
				
				candidates = candidates.map {|p| ::File.expand_path(p)}.uniq
				
				candidates
					.select {|dir| valid_resource_dir?(dir)}
					.sort
					.last
			end
			
			# Check whether a directory looks like a valid clang resource directory.
			# @parameter dir [String | Nil] The directory to check.
			# @returns [Boolean] True if the directory contains expected compiler headers.
			def valid_resource_dir?(dir)
				return false unless dir && ::File.directory?(dir)
				
				inc = ::File.join(dir, "include")
				return false unless ::File.directory?(inc)
				
				::File.exist?(::File.join(inc, "stddef.h")) ||
					::File.exist?(::File.join(inc, "__stddef_size_t.h")) ||
					::File.exist?(::File.join(inc, "stdint.h"))
			end
		end
	end
end
