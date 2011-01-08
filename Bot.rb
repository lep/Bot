#!/usr/bin/env ruby

require 'Connection'
require 'Callback'

module IRC

	class Bot
	  @@valid_types = [:join, :part, :rename, :msg, :priv, :quit]
		@@commands = %w[JOIN PART NICK PRIVMSG QUIT]

		def initialize server, nick, opts={}
			@connection = IRC::Connection.new server, nick, opts
			@callback_classes = Hash.new IRC::SimpleCallback
			@callback_classes[:msg] = IRC::ChannelMessageCallback
			@callback_classes[:priv] = IRC::PrivateMessageCallback
			@callbacks = Hash.new []

			#dispatches every command
			@@commands.each do |command|
				@connection.on command do |params, prefix|
					dispatch command, params, prefix
				end
			end
		end

		def on type, channel=nil, filter=nil, &callback
			@callbacks[type] <<	@callback_classes[type].new(channel, filter, callback)
		end
		
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

		private

		def dispatch command, params, prefix
			if command == "PRIVMSG"
				#TODO check for &channels, aka. server local channels?
				type = params[0][0, 1] == "#" ? :msg : :priv
			else
				#converts the commands to symbols
				#e.g. JOIN => :join
				type = command.downcase.to_sym
			end
			@callbacks[type].each do |callback|
				callback.call prefix, *params
			end
		end

	end
end
