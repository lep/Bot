#!/usr/bin/env ruby

require 'Bot'

$bot = IRC::Bot.new 'irc.quakenet.org', 'sepl'
puts "ASDASD"
$bot.join "#gp39f.tmp"

$bot.on :join do |user, channel|
	puts "#{user} just joined #{channel}"
end

$bot.on :msg do |user, message|
	puts "#{user}> #{message}"
end

while true
end
