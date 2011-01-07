#!/usr/bin/env ruby

module IRC
	
	class SimpleDispatch
		
		def initialize *, &callback
			@callback = callback
		end

		def call prefix, *params
			#It' allways user ACTION parameter
			#e.g. :user NICK new_nick
			#allways prefix ACTION params[0]
			#|user, (channel,message,new_nick)

			#TODO add classes for JOIN and PART? something like
			#on :join, :channel do |user|
			@callback.call prefix, params[0]
		end

	end

	class ChannelMessageDispatch
		def initialize channel=nil, filter=nil, *, &callback
			@type = type
			if channel.is_a? Symbol
				if not filter.is_a? Regexp or filter==nil
					raise "Channel and Filter can't both be strings/symbols"
				end
				channel = "#"+ channe.to_s
			elsif channel.is_a? Regexp
				if filter==nil
					filter, channel = channel, nil
				elsif filter.is_a? Symbol
					filter, channel = channel, "#"+ filter.to_s
				elsif filter.is_a? String
					filter, channel = channel, filter
				else
					raise "Channel and filter can't both be regexp."
				end
			end
			@channel = channel
			@filter = filter
			@callback = callback
		end

		#takes |user, message (, channel) (, matchdata)|
		def call preifx, *params
			if @channel and @channel != params[0]
				#message not in @channel
				return
			end
			if @filter and matchdata = @filter.match params[1]
				if @channel 
					#|user, message, matchdata| since the user
					#allready knows the channel
					@callback.call prefix, params[1], matchdata
				else
					#Since we don't filter for a channel
					#the parameters are |user, message, channel, matchdataæ
					@callback.call prefix, params[1], params[0], matchdata
				end
				return
			end
			#we neither filter for a regexp nor a channel
			#so we provide the channel the message belongs to
			#and no matchdata
			#|user, message, channel|
			@callback.call prefix, params[1], params[0]
		end
	end

	class PrivateMessageDispatch
		#takes |user, message (, matchdata)|
		def initialize filter=nil, *, &callback
			@filter = filter
			@callback = callback
		end

		def call prefix, *params
			if @filter!=nil
				if matchdata = @filter.match params[1]
					@callback.call prefix, params[1], matchdata
				end
			else
				@callback.call prefix, params[1]
			end
		end
	end

end
