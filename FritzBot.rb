#!/usr/bin/ruby

require 'discordrb'
require_relative 'MonkeyPatches.rb'
require_relative 'Config.rb'
require_relative 'Commands.rb'
require_relative 'FritzServer.rb'
require_relative 'Events.rb'

# Set bot configuration
$config = Config.new
$permissions = Permissions.new
$version = "alpha-0.10"
$running = true

# I'm SO sorry! It's either this, a seperate command registerer, or an ugly monkey patch! If you have better solution feel free to voice it.
$bot = Discordrb::Commands::CommandBot.new token: $config['token'], \
                                                 application_id: $config['application_id'], \
                                                 prefix: '!', \
                                                 command_doesnt_exist_message: "**Invalid Command** Please type `!help` for a list of *valid* commands."


puts "This bot's invite URL is #{$bot.invite_url}."
Commands.register_commands

$bot.run_async

$bot.servers.each do |key, value|
    FritzServer.add(value, FritzServer.new(value))
end

$bot.sync