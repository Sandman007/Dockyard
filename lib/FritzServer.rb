#!/usr/bin/ruby

require 'discordrb'
require_relative 'MonkeyPatches.rb'
require_relative 'Config.rb'

class FritzServer
    @@servers = {}
    attr_accessor :setup_state
    def initialize(server, bot)
        @roles = {}
        @configuration = Permissions.new(server.id, server.name)
        @server = server
        @bot = bot
        server.roles.each do |role|
            @roles[role.name.downcase] = role
        end
        if @configuration.isnew then
            @configuration['default_channel'] = server.default_channel.id
            server.general_channel.send_message(
            "Hello! My name is Fritz!\n"\
            "This server has not been configured yet, or is new to me. "\
            "Someone with the permission `manage_server` (usually the owner) "\
            "please use the `!setup` command to configure me. Thank you :)")
        end
    end

    def [](key)
        return @roles[key]
    end

    def []=(key, value)
        @roles[key] = value
    end

    def self.add(server, fritzserver)
        @@servers[server] = fritzserver
    end

    def self.remove(server)
        @@servers[server] = nil
    end

    def self.get(server)
        return @@servers[server]
    end

    def get_configuration
        return @configuration
    end

    def find_member(str)
        if str =~ /<@[0-9]+>/
            member = @bot.parse_mention(str)
            

    end

    def find_role(str)
        if str =~ /<@[0-9]*>/
            role = @server.role(str.gsub(/[<@>]*/, '').to_i)
            return role
        else
            role = @roles[str.downcase]
            return role
        end
    end
end
