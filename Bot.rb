#!/usr/bin/env ruby

require 'Connection'

module IRC
	class Bot
		def initialize server, nick, opts={}
			@connection = IRC::Connection.new server, nick, opts
		end

		#def on(join|part|rename|msg|priv, &block)
		
		def join channel, password=nil
			@connection.send "JOIN #{channel} #{password}".strip
		end
		
		def part channel
			@connection.send "PART #{channel}"
		end
		
		def msg to, what
			@connection.send "PRIVMSG #{to} :#{what}"
		end
		
		def topic what
			@connection.send "TOPIC :#{what}"
		end
	end
end
