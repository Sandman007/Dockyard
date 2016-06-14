#!/usr/bin/ruby

require 'discordrb'
require 'dentaku'
require_relative 'MonkeyPatches.rb'
require_relative 'FritzServer.rb'
require_relative 'Config.rb'

class Commands
    class << self
        def check_perms?(command, event)
            unless $permissions.can_use_command?(command, event.author) then
                event.respond("You do not have access to that command!")
                return false
            else
                return true
            end
        end
            
        def register_commands
            $bot.command(:ping,
                        description: 'Pong!',
                        usage: "") do |event|
                next unless check_perms?('ping', event)
                event.respond('Pong!')
                nil
            end

            $bot.command(:random,
                        min_args: 0,
                        max_args: 2,
                        description: 'Generates a random number between 0 and 1, 0 and max or min and max.',
                        usage: '(min) <max>') do |_event, min, max|
                
                next unless check_perms?('random', event)
                if max
                  rand(min.to_i..max.to_i)
                elsif min
                  rand(0..min.to_i)
                else
                  rand
                end
            end
            
            $bot.command(:choose,
                        min_args: 2,
                        description: 'Based on math, selects a choice fairly.',
                        usage: '<firstChoice>, <secondChoice>, (thirdChoice), (fourthChoice), ...') do |event, *args|
                
                next unless check_perms?('choose', event)
                choices = args.join(" ").split(',')
                output = $config['choice_prefixes'].sample
                output += choices.sample
                output += "."
                output = output.squeeze(" ").strip
                event.respond(output)
                nil
            end
            
            $bot.command(:setregion,
                        min_args: 1,
                        description: "Sets your region, case insensitive.",
                        usage: "<Australia/Canada/China/England/Germany/United States/...>") do |event, *args|
                
                next unless check_perms?('setregion', event)
                selectedregion = args.join(" ").downcase
                fritz = FritzServer.get(event.author.server)
                if fritz[selectedregion] == nil then
                    event.respond("That region doesn't exist! (on the server)")
                    next
                end
                if event.author.role?(fritz[selectedregion]) == true then
                    event.respond("You already have that region assigned.")
                    next
                end
                
                $config['regions'].each do |role| # Remove users current region
                    roleobject = fritz[role.downcase]
                    if roleobject == nil then
                        event.respond("Internal error: " + __FILE__ + "@" + __LINE__)
                        puts "There is a role in 'regions' that doesn't exist on the server!"
                        next
                    elsif event.author.role?(roleobject) then
                        event.author.remove_role(roleobject)
                    end
                end
                event.author.add_role(fritz[selectedregion])
                event.respond("#{event.author.name}'s region has been set to #{selectedregion.capitalize}")
                nil
            end
            
            $bot.command(:availableregions,
                        description: "Lists available regions.",
                        usage: "") do |event|
                
                next unless check_perms?('availableregions', event)
                output = ""
                $config['regions'].each do |role|
                    output += role
                    output += "\n"
                end
                event.respond(output)
            end
            
            $bot.command(:exit,
                        description: "Shuts the bot down.",
                        usage: "") do |event|
                
                next unless check_perms?('exit', event)
                event.respond("Shutting down.")
                $running = false
                # event.author.server.leave
                exit
            end
            
            $bot.command(:about,
                        description: "Displays information about the bot.",
                        usage: "") do |event|
                
                next unless check_perms?('about', event)
                output = "```\n"
                output += "Author\n"
                output += "    Austin Martin (Evalelynn#3885)\n"
                output += "Library\n"
                output += "    discordrb\n"
                output += "Version\n"
                output += "    #{$version}\n"
                output += "GitHub Page\n"
                output += "    https://github.com/Evalelynn/FritzBot\n"
                output += "Official Server\n"
                output += "    http://discordapp.com/invite/012epqCAIjp8UGKGJ\n"
                output += "```"
                event.respond(output)
            end
            
            $bot.command(:reload,
                        description: "Reloads configuration files.",
                        usage: "") do |event|
                
                next unless check_perms?('reload', event)
                event.respond("Reloading, please standby.")
                $config = Config.new
                $permissions = Permissions.new
                FritzServer.remove(event.user.server)
                fserv = FritzServer.new(event.user.server)
                FritzServer.add(event.user.server, fserv)
                event.respond("Done!")
            end
            
            $bot.command(:saveconfig,
                        description: "Saves configuration files.",
                        usage: "") do |event|
                
                next unless check_perms?('saveconfig', event)
                $config.save
                $permissions.save
                event.respond("Done!")
            end
            
            $bot.command(:givecommand,
                        min_args: 2,
                        max_args: 2,
                        description: "Gives access to specifed command to specifed role, case sensitive!",
                        usage: "<command> <role>") do |event, command, role|
                
                next unless check_perms?('givecommand', event)
                $permissions.bot.command_to_role(command, role)
                event.respond("Added!")
            end
            
            $bot.command(:removecommand,
                        min_args: 2,
                        max_args: 2,
                        description: "Removes access to specified command from specified role, case sensitive!",
                        usage: "<command> <role>") do |event, command, role|
                
                next unless check_perms?('removecommand', event)
                $permissions.remove_command_from_role(command, role)
                event.respond("Removed!")
            end
            
            $bot.command(:addregion,
                        min_args: 1,
                        description: "Adds a region to the configuration, case sensetive",
                        usage: "<region>") do |event, *arg|
                
                next unless check_perms?('addregion', event)
                $config.add_region(arg.join(" "))
                event.respond("Added!")
            end
            
            $bot.command(:delregion,
                        min_args: 1,
                        description: "Removes a region to the configuration, case sensetive.",
                        usage: "<region>") do |event, *arg|
                
                next unless check_perms?('delregion', event)
                $config.delete_region(arg.join(" "))
                event.respond("Removed!")
            end
            
            $bot.command(:time,
                        description: "Displays the current time.",
                        usage: "") do |event|
                next unless check_perms?('time', event)
                
                event.respond("Good heavens, it's high noon!")
            end
            
            $bot.command(:calc,
                         description: "Evaluates a mathematical formula.",
                         usage: "<some math here>") do |event, *args|
                
                next unless check_perms?('calc', event)
                begin
                    equation = args.join(" ")
                    response = ( "%.15f" % Dentaku(equation) ).sub(/0*$/,"")
                    event.respond("```\n #{response} \n```")
                rescue => error
                    event.respond("**INTERNAL ERROR:** #{error.message}")
                end
            end
            
            $bot.command(:help,
                        max_args: 1,
                        description: "Shows a list of all the commands available or displays help for a specific command.",
                        usage: "[command name]") do |event, command_name|
                
                next unless check_perms?('help', event)
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
                    @@organized_commands ||= $bot.commands.to_a.sort_by { |a| a[0].to_s.downcase }
                    @@organized_commands.each do |command|
                        output += "!#{command[1].name.to_s} #{command[1].attributes[:usage]}\n"
                        output += "    #{command[1].attributes[:description] || "No description available."}\n"
                    end
                end
                output += "\n```"
                event.respond(output)
                nil
            end
        end
    end
end
