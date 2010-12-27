#!/usr/bin/env ruby

require 'socket'

module IRC
	class Connection
		def initialize server, nick, opts={}
			opts[:port] ||= 6667
			opts[:server] = server
			opts[:nick] = nick
			@option=opts

			connect
			listen
		end

		private

		def connect
			socket = TCPSocket.open(@config[:server], @config[:port])

			if @config.ssl
				begin require 'openssl' 
				rescue raise "Cannot load openssl-library" 
				end

				context = OpenSSL::SSL::SSLContext.new
				context.verify_mode = OpenSSL::SSL::VERIFY_NONE
				
				socket = OpenSSL::SSL::SSLSocket.new(socket, context)
				socket.sync = true
				socket.connect
			end

			@socket = socket
		end

		def listen
			Thread.new do
				while line = @socket.gets
					parse line
				end
			end
		end

		def parse line
			match = /(?:^:(\S+) )(\S+) (.+)/.match line
			if match[2] =~ /:/
				params = $~.pre_match.split
				params << ":" + $~.post_match
			else
				params = match[2].split
			end
		end
	end
end
