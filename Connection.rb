#!/usr/bin/env ruby

require 'socket'
require 'Queue'

module IRC
	class Connection
		def initialize server, nick, opts={}
			opts[:port] ||= 6667
			opts[:server] = server
			opts[:nick] = nick
			opts[:name] ||= nick
			@config=opts

			@callbacks = Hash.new []
			@queue = IRC::Queue.new

			@ready = []

			connect
			connect_irc
			listen
			@queue.lock
		end

		def send msg
			if msg.length > 510 #512 - "\r\n".length
				raise "Message too long."
			end
			@queue << msg
			try_to_send
			#@socket.puts msg + "\r\n"
		end

		def on command, &callback
			@callbacks[command] << callback
		end


		private

		def try_to_send
			loop do
				if @queue.empty? || @queue.locked?
					break
				else
					#TODO flood protection. see RFC 2813 section 5.8
					@socket.puts @queue.remove + "\r\n"
				end
			end
		end

		def ping
			@socket.puts "PING :#{@config[:server]}\r\n"
			@queue.lock
		end

		def connect
			socket = TCPSocket.open(@config[:server], @config[:port])

			if @config[:ssl]
				#I once had a really nasty error-msg, so this should help.
				require 'openssl' rescue raise "Cannot load openssl-library (libssl-dev)." 

				context = OpenSSL::SSL::SSLContext.new
				context.verify_mode = OpenSSL::SSL::VERIFY_NONE
				
				socket = OpenSSL::SSL::SSLSocket.new(socket, context)
				socket.sync = true
				socket.connect
			end

			@socket = socket
		end

		def connect_irc
			send "PASS #{@config[:password]}" if @config[:password]
			send "NICK :#{@config[:nick]}"
			send "USER #{@config[:name]} 0 * :#{@config[:nick]}"
		end

		def listen
			Thread.new do
				while line = @socket.gets
					puts "<< #{line}"
					parse line
				end
			end.join
		end

		def parse line
			m = /(?:^:(\S+) )?(\S+) (.+)/.match line
			if m[3] =~ /:/
				params = $~.pre_match.split
				params << ":" + $~.post_match
			else
				params = m[3].split
			end
			prefix, command = m[1, 2]
			
			if command == "PING"
				send "PONG #{params[0]}"
				@queue.unlock
			elsif command == "PONG"
				@queue.unlock
			elsif ('001' .. '004').include? command
				if ready? command
					@queue.unlock
					try_to_send
				end
			else
				dispatch command, params, prefix
			end
		end

		def dispatch command, params, prefix
			@callbacks[command].each do |cb|
				cb.call(params, prefix)
			end
		end

		def ready? command
			@ready << command
			(('001' .. '004').to_a - @ready).empty?
		end
	end
end
