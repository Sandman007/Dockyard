#!/usr/bin/ruby

require 'discordrb'
require_relative 'MonkeyPatches.rb'

class FritzServer
    @@servers = {}
    def initialize(server)
        @roles = {}
        server.roles.each do |role|
            @roles[role.name.downcase] = role
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
