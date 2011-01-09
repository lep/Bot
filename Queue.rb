#!/usr/bin/env ruby

module IRC

	class Queue
		def initialize
			@locked = false
			@queue = []
		end

		def << params
			@queue << params
		end

		def lock
			@locked = true
		end

		def unlock
			@locked = false
		end

		def locked?
			@locked
		end

		def empty?
			@queue.empty?
		end

		def first
			@queue.first
		end

		def remove
			unless locked?
				@queue.shift
			end
		end
	end
end
