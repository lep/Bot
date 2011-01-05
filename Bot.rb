#!/usr/bin/env ruby

require 'Connection'

module IRC

	class Bot
	  @@valid_types = [:join, :part, :rename, :msg, :priv, :quit]
		@@simple_commands = %w{JOIN PART QUIT NICK QUIT}
		@@command_to_symbol = {}

		def initialize server, nick, opts={}
			@connection = IRC::Connection.new server, nick, opts

			#table for simple commands with a specifi pattern
			#callback(prefix, params[0])
			@@simple_commands.each do |command|
				@@command_to_symbol[command]=command.downcase.to_sym
			end

			#for me, this is not the priciple of lest surprise
			#i mean that concant of an array for one element
			#i'd wish for something like (ary + element).each

			#dispatches every command
			@@simple_commands.concat(["PRIVMSG"]).each do |command|
				@connection.on command do |params, prefix|
					dispatch command, params, prefix
				end
			end
			@callbacks = Hash.new []
		end

		#def on(join|part|rename|msg|priv|quit, &block)
		=begin example
			def on :msg, :channel, /^!(.*)$/ do |user, msg, match|
			end

			def on :msg, "#gp39f.tmp" do |user, msg|
			end

			def on :msg, :rant do |user, msg|
			end

			def on :msg, /\d{32}/ do |user, msg, channel, match|
			end
		=end

		def on type, channel=nil, regexp=nil, &callback
			unless @@valid_types.contains? type
				raise "Type (#{type}) not known."
			end
			
			count = 0
			count +=1 if channel
			count +=1 if regexp
			
			#makes it possible to swap channel and regexp in parameter-list
			if channel.is_a? Symbol
				channel="#" + channel.to_s
			elsif channel.is_a? Regexp
				if regexp==nil
					regexp, channel = channel, nil
				elsif regexp.is_a? String
					channel, regexp = regexp, channel
				else
					raise "Channel and regexp can't both be regexp."
				end
			end

			if type==:msg || type==:privmsg
				if callback.arity - 2 != count
					raise "Parameter count wrong..."
				end
			else
			end

			#TODO make own class (for PRIVMSG)?
			@callbacks[action] <<
				{ :callback => callback
				, :regexp => regexp
				, :channel => channel
				}
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

		#TODO redo
		#TODO add channel and regexp parameters
		private


		def dispatch command, params, prefix
			if @@simple_commands.contains? command
				@callbacks[@@command_to_symbol[command]].each do |cb|
					cb.call prefix, params[0]
				end
			else
				unless command == "PRIVMSG"
					raise "Unknown Command."
				end

				if params[0, 1] =="#"
					@callbacks[:msg].each do |cb|
						cb.call prefix, params[0], params[1]
					end
				else
					@callbacks[:priv].each do |cb|
						cb.call prefix, params[1]
					end
				end
			end
		end

	end
end
