#!/usr/bin/ruby

require 'discordrb'
require 'dentaku'
require 'thread'
require_relative 'MonkeyPatches.rb'
require_relative 'FritzServer.rb'
require_relative 'Config.rb'
require_relative 'RadioBot.rb'
require_relative 'Plugins.rb'

alias can_use? Plugins.can_use?

def register_commands

    # $bot.command(:setregion,
    #             min_args: 1,
    #             description: "Sets your region, case insensitive.",
    #             usage: "<Australia/Canada/China/England/Germany/United States/...>") do |event, *args|
    #
    #     next unless can_use?('setregion', event)
    #     selectedregion = args.join(" ").downcase
    #     fritz = FritzServer.get(event.author.server)
    #     if fritz[selectedregion] == nil then
    #         event.respond("That region doesn't exist! (on the server)")
    #         next
    #     end
    #     if event.author.role?(fritz[selectedregion]) == true then
    #         event.respond("You already have that region assigned.")
    #         next
    #     end
    #
    #     $config['regions'].each do |role| # Remove users current region
    #         roleobject = fritz[role.downcase]
    #         if roleobject == nil then
    #             event.respond("Internal error: " + __FILE__ + "@" + __LINE__)
    #             puts "There is a role in 'regions' that doesn't exist on the server!"
    #             next
    #         elsif event.author.role?(roleobject) then
    #             event.author.remove_role(roleobject)
    #         end
    #     end
    #     event.author.add_role(fritz[selectedregion])
    #     event.respond("#{event.author.name}'s region has been set to #{selectedregion.capitalize}")
    #     nil
    # end
    #
    # $bot.command(:availableregions,
    #             description: "Lists available regions.",
    #             usage: "") do |event|
    #
    #     next unless can_use?('availableregions', event)
    #     output = ""
    #     $config['regions'].each do |role|
    #         output += role
    #         output += "\n"
    #     end
    #     event.respond(output)
    # end

    $bot.command(:reload,
                description: "Reloads configuration files.",
                usage: "") do |event|

        break unless can_use?('reload', event)
        event.respond("Reloading, please standby.")
        $config = Config.new
        Permissions.reload
        FritzServer.remove(event.user.server)
        fserv = FritzServer.new(event.user.server)
        FritzServer.add(event.user.server, fserv)
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
