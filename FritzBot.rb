#!/usr/bin/ruby

# EXPERIMENTAL: Tail call optimization (TCO)
RubyVM::InstructionSequence.compile_option = {
    tailcall_optimization: true,
    trace_instruction: false
}

require 'discordrb'
require 'video_info'
require_relative 'lib/MonkeyPatches.rb'
require_relative 'lib/Config.rb'
require_relative 'lib/InternalCmds.rb'
require_relative 'lib/FritzServer.rb'
require_relative 'lib/Events.rb'
require_relative 'lib/Plugins.rb'

# Set bot configuration
$config = Config.new
# $permissions = Permissions.new
$version = "alpha v1.1"
$running = true
$plugins = {}

# I'm SO sorry! It's either this, a seperate command registerer, or an ugly monkey patch! If you have better solution feel free to voice it.
$bot = Discordrb::Commands::CommandBot.new token: $config['token'], \
                                                 application_id: $config['application_id'], \
                                                 prefix: '!', \
                                                 command_doesnt_exist_message: "**Invalid Command** Please type `!help` for a list of *valid* commands."


VideoInfo.provider_api_keys = { youtube: $config['google_api_key'] }

puts "This bot's invite URL is #{$bot.invite_url}."

register_commands

$bot.run_async

$bot.servers.each do |key, value|
    FritzServer.add(value, FritzServer.new(value), $bot)
end


$bot.sync
