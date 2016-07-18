#!/usr/bin/ruby

require 'discordrb'
require 'dentaku'
require 'thread'
require_relative 'MonkeyPatches.rb'
require_relative 'FritzServer.rb'
require_relative 'Config.rb'
require_relative 'RadioBot.rb'


def can_use?(command, event)
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
        next unless can_use?('ping', event)
        event.respond('Pong!')
        nil
    end

    $bot.command(:random,
                min_args: 0,
                max_args: 2,
                description: 'Generates a random number between 0 and 1, 0 and max or min and max.',
                usage: '(min) <max>') do |_event, min, max|

        next unless can_use?('random', event)
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

        next unless can_use?('choose', event)
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

        next unless can_use?('setregion', event)
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

        next unless can_use?('availableregions', event)
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

        next unless can_use?('exit', event)
        event.respond("Shutting down.")
        $running = false
        # event.author.server.leave
        exit
    end

    $bot.command(:about,
                description: "Displays information about the bot.",
                usage: "") do |event|

        next unless can_use?('about', event)
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

        next unless can_use?('reload', event)
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

        next unless can_use?('saveconfig', event)
        $config.save
        $permissions.save
        event.respond("Done!")
    end

    $bot.command(:givecommand,
                min_args: 2,
                max_args: 2,
                description: "Gives access to specifed command to specifed role, case sensitive!",
                usage: "<command> <role>") do |event, command, role|

        next unless can_use?('givecommand', event)
        $permissions.bot.command_to_role(command, role)
        event.respond("Added!")
    end

    $bot.command(:removecommand,
                min_args: 2,
                max_args: 2,
                description: "Removes access to specified command from specified role, case sensitive!",
                usage: "<command> <role>") do |event, command, role|

        next unless can_use?('removecommand', event)
        $permissions.remove_command_from_role(command, role)
        event.respond("Removed!")
    end

    $bot.command(:addregion,
                min_args: 1,
                description: "Adds a region to the configuration, case sensetive",
                usage: "<region>") do |event, *arg|

        next unless can_use?('addregion', event)
        $config.add_region(arg.join(" "))
        event.respond("Added!")
    end

    $bot.command(:delregion,
                min_args: 1,
                description: "Removes a region to the configuration, case sensetive.",
                usage: "<region>") do |event, *arg|

        next unless can_use?('delregion', event)
        $config.delete_region(arg.join(" "))
        event.respond("Removed!")
    end

    $bot.command(:time,
                description: "Displays the current time.",
                usage: "") do |event|
        next unless can_use?('time', event)

        event.respond("Good heavens, it's high noon!")
    end

    $bot.command(:calc,
                 description: "Evaluates a mathematical formula.",
                 usage: "<some math here>") do |event, *args|

        next unless can_use?('calc', event)
        begin
            equation = args.join(" ").gsub("`", "")
            if equation == "((12+144+20+3*sqrt(4))/7)+(5*11)=9^2+0" then # This needed to be done
                event.respond("```\nA dozen, a gross, and a score,\n"\
                              "Plus three times the square root of four,\n"\
                              "Divided by seven,\n"\
                              "Plus three times eleven,\n"\
                              "Equals nine squared and not a bit more.\n```")
                event.respond("```\n81.\n```")
                next
            end
            result =  Dentaku(equation, pi: 3.14159265359)
            if [true, false].include? result then
                event.respond("```\n#{result}```\n")
            else
            response = ( "%.15f" % result ).sub(/0*$/,"")
            event.respond("```\n #{response} \n```")
            end
        rescue => error
            event.respond("**INTERNAL ERROR:** #{error.message}")
        end
    end

    $bot.command(:radio,
                 description: "It's a radio, for playing music.",
                 usage: "<add/pause/play/skip/replay/nowplaying/queue/enable/disable> [options]") do |event, cmd, *args|

        next unless can_use?('radio', event)
        radio = RadioBot.getbot(event.user.server)
        if cmd == "add" then
            if radio == nil then
                event.respond("Bot is diabled on this server, please enable it first.")
                next
            end
            event.respond("Attempting to download song, please be patient.")
            resp = radio.addsong(args[0])
            if resp == "OK"
                event.respond("Song successfully added!")
            else
                event.respond("Invalid song.")
            end
        elsif cmd == "pause"
            if radio == nil then
                event.respond("Bot is diabled on this server, please enable it first.")
                next
            end
            radio.pause
            event.respond("Paused.")
        elsif cmd == "play" then
            if radio == nil then
                event.respond("Bot is diabled on this server, please enable it first.")
                next
            end
            radio.play
            event.respond("Now playing.")
        elsif cmd == "skip"
            if radio == nil then
                event.respond("Radio is diabled on this server, please enable it first.")
                next
            end
            radio.skip((args[0].to_i || 1))
            event.respond("Skipped #{(args[0] || 1)} songs.")
        elsif cmd == "nowplaying" then
            if radio == nil then
                event.respond("Radio is diabled on this server, please enable it first.")
                next
            end
            info = radio.currentsong
            unless info == nil then
                output = "```\nTitle: #{info[:title]}\n"
                output+= "Author: #{info[:author]}\n"
                output+= "Duration: #{info[:duration]} seconds\n"
                output+= "Playlist: #{info[:playlist]}\n```"
                event.respond(output)
            else
                event.respond("Nothing is currently playing.")
            end
        elsif cmd == "replay" then
            if radio == nil then
                event.respond("Radio is diabled on this server, please enable it first.")
                next
            end
            event.respond("Attempting to replay current song.")
            radio.replay
        elsif cmd == "enable"
            if radio != nil then
                event.respond("Radio is already running. Try turning it off before starting it, thank you.")
                next
            end
            radio = RadioBot.new($bot, event.author.server)
            t = Thread.new { radio.run }
            event.respond("Bot started.")
        elsif cmd == "disable" then
            if radio == nil
                event.respond("Bot isn't running. Please try starting before turning it off, thank you.")
                next
            end
            radio.close
            event.respond("Radio has been disabled.")
        elsif cmd == "queue" then
            if radio == nil
                event.respond("Bot isn't running. Please try starting before turning it off, thank you.")
                next
            end
            queue = radio.getqueue
            secondqueue = Queue.new
            if queue.empty? then
                event.respond("No songs in queue.")
            else
                output = "```\n#{queue.size} songs in queue.\n"
                until queue.empty? do
                    info = queue.pop
                    secondqueue.push(info)
                    output+= "#{info[:title]}\n"
                end
                radio.setqueue(secondqueue)
                output += "\n```"
                event.respond(output)
            end
        else
            event.respond("Invalid command. Nice try though.")
        end
        nil
    end

    $bot.command(:debug_listchannels,
                 description: "Lists all channels in the current server.",
                 usage: "") do |event|

        next unless can_use?('debug', event)
        output = ""
        event.author.server.channels.each do |channel|
            output += channel.name + "\n"
        end

        event.respond(output)
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
