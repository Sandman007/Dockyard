#!/usr/bin/ruby

require 'discordrb'
require_relative 'FritzServer.rb'
require_relative 'Config.rb'

module Plugins
    def self.can_use?(permission, event, silent = false)
        if Permissions.can_use_restricted?(event.user) then
            return true
        elsif Permissions.is_restricted?(permission) then
            event.respond("Sorry, that permission is restricted.") unless silent
            return false
        elsif event.user.owner? || Permissions.user_has_permission?(permission, event.author, event.server.id)
            return true
        else
            event.respond("You do not have access to that permission.") unless silent
            return false
        end
    end

    def self.(bot)
        Dir.foreach('plugins') do |item|
            if item.end_with?('.rb') then
                require_relative(item)
                item.sub!('.rb', '')
                eval("")
            end
        end
    end

    def self.load_plugin(plugin, bot)
        require_relative("../plugins/#{plugin}")
        pl = eval("pl = #{plugin.sub('.rb', '')}.new") # There is prob a better way
        pl.enable(bot)
        return pl
    end

    def self.unload_plugin(plugin, bot)
        pl = $plugins['']


end
