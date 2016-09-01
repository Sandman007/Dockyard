#!/usr/bin/ruby

require 'discordrb'
require 'dentaku'
require 'thread'
require_relative 'MonkeyPatches.rb'
require_relative 'DockServer.rb'
require_relative 'Config.rb'
require_relative 'RadioBot.rb'
require_relative 'Plugins.rb'

def can_use?(name, event)
    return Plugins.can_use?(name, event)
end

def register_commands

    $bot.command(:reload,
                description: "Reloads configuration files.",
                usage: "") do |event|

        break unless can_use?('reload', event)
        event.respond("Reloading, please standby.")
        $config = Config.new
        Permissions.reload
        DockServer.remove(event.user.server)
        fserv = DockServer.new(event.user.server)
        DockServer.add(event.user.server, fserv)
        event.respond("Done!")
    end

    $bot.command(:saveconfig,
                description: "Saves configuration files.",
                usage: "") do |event|

        break unless can_use?('saveconfig', event)
        $config.save
        Permissions.save
        event.respond("Done!")
    end

    $bot.command(:config,
                 description: "Configures the server",
                 usage: "[option] [value]") do |event, subcommand, *args|

        next unless can_use?('config', event)



    end

    $bot.command(:set,
                 min_args: 1,
                 description: "Sets various config options",
                 usage: "[subcommand] [args]") do |event, subcommand,  *args|

        next unless can_use?('setrole', event)

    end

    $bot.command(:help,
                max_args: 1,
                description: "Shows a list of all the commands available or displays help for a specific command.",
                usage: "[command name]") do |event, command_name|

        next unless can_use?('help', event)
        output = "```\n"
        if command_name then
            command = $bot.commands[command_name.to_sym]
            unless command then
                output += "Please enter a valid command.\n"
            else
                output += "!"
                output += command.name.to_s
                output += " "
                output += command.attributes[:usage] || " "
                output += "\n"
                output += command.attributes[:description] || "No description available."
            end
        else
            $organized_commands ||= $bot.commands.to_a.sort_by { |a| a[0].to_s.downcase }
            $organized_commands.each do |command|
                output += "!#{command[1].name.to_s} #{command[1].attributes[:usage]}\n"
                output += "    #{command[1].attributes[:description] || "No description available."}\n"
            end
        end
        output += "\n```"
        event.respond(output)
        nil
    end
end
