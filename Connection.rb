#!/usr/bin/env ruby

require 'socket'

module IRC
	class Connection
		def initialize server, nick, opts={}
			opts[:port] ||= 6667
			opts[:server] = server
			opts[:nick] = nick
			@option=opts

			@callbacks = Hash.new []

			connect
			listen
		end

		def send msg
			if msg.length > 510
				raise "Message too long."
			end
			@socket.puts msg + "\r\n"
		end

		def on command, &callback
			@callbacks[command] << callback
		end


		private

		def connect
			socket = TCPSocket.open(@config[:server], @config[:port])

			if @config.ssl
				#I once had a really nasty error-msg, so this should help.
				require 'openssl' rescue raise "Cannot load openssl-library (libssl-dev)." 

				context = OpenSSL::SSL::SSLContext.new
				context.verify_mode = OpenSSL::SSL::VERIFY_NONE
				
				socket = OpenSSL::SSL::SSLSocket.new(socket, context)
				socket.sync = true
				socket.connect
			end

			@socket = socket

			connect_irc
		end

		def connect_irc
			send "PASS #{@options[:password]}" if @options[:password]
			send "NICK :#{@options[:nick]}"
			send "USER #{@options[:name]} 0 * :#{@options[:nick]}"
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
			prefix, command = match[0, 2]
			
			if command == "PING"
				send "PONG #{params[0]}"
			else
				dispatch command, params, prefix
			end
		end

		def dispatch command, params, prefix
			@callbacks[command].each do |cb|
				cb.call(params, prefix)
			end
		end
	end
end
