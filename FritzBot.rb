#!/usr/bin/ruby

require 'discordrb'
require 'video_info'
require_relative 'lib/MonkeyPatches.rb'
require_relative 'lib/Config.rb'
require_relative 'lib/Commands.rb'
require_relative 'lib/FritzServer.rb'
require_relative 'lib/Events.rb'

# Set bot configuration
$config = Config.new
# $permissions = Permissions.new
$version = "alpha v1.1"
$running = true

# I'm SO sorry! It's either this, a seperate command registerer, or an ugly monkey patch! If you have better solution feel free to voice it.
$bot = Discordrb::Commands::CommandBot.new token: $config['token'], \
                                                 application_id: $config['application_id'], \
                                                 prefix: '!', \
                                                 command_doesnt_exist_message: "**Invalid Command** Please type `!help` for a list of *valid* commands."


VideoInfo.provider_api_keys = { youtube: $config['youtube_api_key'] }

puts "This bot's invite URL is #{$bot.invite_url}."
register_commands

$bot.run_async

$bot.servers.each do |key, value|
    FritzServer.add(value, FritzServer.new(value))
end


$bot.sync
