#!/usr/bin/env ruby

require 'Connection'

module IRC

	class Bot
	  @@valid_types = [:join, :part, :rename, :msg, :priv, :quit]

		def initialize server, nick, opts={}
			@connection = IRC::Connection.new server, nick, opts
			%w{JOIN PART PRIVMSG QUIT}.each do |command|
				@connection.on command, do |params, prefix|
					dispatch command, params, prefix
				end
			end
			@callbacks = Hash.new []
		end

		#def on(join|part|rename|msg|priv|quit, &block)
		=begin example
			def on :msg, :channel, /^!(.*)$/ do |user, msg, channel, match_data|
				
			end

			def on :msg, "#gp39f.tmp" do |user, msg|

			end

			def on :msg, :rant do |user, msg|

			end

			def on 
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

			@callbacks[action] << callback
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
			case command
			when "JOIN" #|user, channel|
				@callbacks[:join].each do |cb|
					cb.call prefix, params[0]
				end
			when "PART" #|user, channel|
				@callbacks[:part].each do |cb|
					cb.call prefix, params[0]
				end
			when "NICK" #|user, new_name|
				@callbacks[:nick].each do |cb|
					cb.call prefix, *params
				end
			when "QUIT" #|user, quit_msg|
				@callbacks[:quit].each do |cb|
					cb.call prefix, params[0]
				end
			when "PRIVMSG" #|user,(channel,) msg|
				if params[0].chr =="#"
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
