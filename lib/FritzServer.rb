#!/usr/bin/ruby

require 'discordrb'
require_relative 'MonkeyPatches.rb'
require_relative 'Config.rb'

class FritzServer
    @@servers = {}
    def initialize(server)
        @roles = {}
        @configuration = Permissions.new(server.id, server.name)
        server.roles.each do |role|
            @roles[role.name.downcase] = role
        end
        if @configuration['configured'] != true then
            server.general_channel.send_message(
            "Hello! My name is Fritz!\n"
            "This server has not been configured yet, or is new to me."
            "Someone with the permission `manage_server` (usually the owner)"
            "please use the `!setup` command to configure me. Thank you :)"
            )
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
end
