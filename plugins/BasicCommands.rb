#!/usr/bin/ruby

require 'dentaku'

module Plugins
    class BasicCommands
        def enable(bot)
            bot.command(:ping,
                        description: 'Pong!',
                        usage: "",
                        &method(:cmd_ping))

            bot.command(:random,
                        min_args: 0,
                        max_args: 2,
                        description: 'Generates a random number between 0 and 1, 0 and max or min and max.',
                        usage: '(min) <max>',
                        &method(:cmd_random))
            bot.command(:choose,
                        min_args: 2,
                        description: 'Based on math, selects a choice fairly.',
                        usage: '<firstChoice>, <secondChoice>, (thirdChoice), ...',
                        &method(:cmd_choose))

            bot.command(:about,
                        description: "Displays information about the bot.",
                        usage: "",
                        &method(:cmd_about))
            bot.command(:time,
                        description: "Displays the current time.",
                        usage: "",
                        &method(:cmd_time))
            bot.command(:calc,
                         description: "Evaluates a mathematical formula.",
                         usage: "<some math here>",
                         &method(:cmd_calc))
            bot.command(:exit,
                        description: "Shuts down the bot.",
                        usage: "",
                        &method(:cmd_exit))
            bot.command(:eval,
                        min_args: 1,
                        description: "Runs the supplied Ruby code.",
                        usage: "[ruby code]",
                        &method(:cmd_eval))

            bot.debug("BasicCommands enabled")
        end

        def disable(bot)
            bot.remove_command(:ping)
            bot.remove_command(:random)
            bot.remove_command(:choose)
            bot.remove_command(:about)
            bot.remove_command(:time)
            bot.remove_command(:calc)
            bot.remove_command(:exit)
            bot.remove_command(:eval)

            bot.debug("BasicCommands disabled")
        end

        private
        
        def cmd_ping(event)
            break unless can_use?('ping', event)
            event.respond('Pong!')
            nil
        end

        def cmd_random(event, min, max)
            break unless can_use?('random', event)
            if max
              rand(min.to_i..max.to_i)
            elsif min
              rand(0..min.to_i)
            else
              rand
            end
        end

        def cmd_choose(event, *args)
            break unless can_use?('choose', event)
            choices = args.join(" ").split(',')
            output = $config['choice_prefixes'].sample
            output += choices.sample
            output += "."
            output = output.squeeze(" ").strip
            event.respond(output)
            nil
        end

        def cmd_about(event)
            break unless can_use?('about', event)
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
            event.respond(output
        end

        def cmd_time(event) # Lame joke, may be removed
            break unless can_use?('time', event)
            event.respond("Good heavens, it's high noon!")
        end

        def cmd_calc(event, *args)
            break unless can_use?('calc', event)
            begin
                equation = args.join(" ").gsub("`", "")
                # I'm so sorry
                if equation == "((12+144+20+3*sqrt(4))/7)+(5*11)=9^2+0" then
                    event.respond("```\nA dozen, a gross, and a score,\n"\
                                  "Plus three times the square root of four,\n"\
                                  "Divided by seven,\n"\
                                  "Plus three times eleven,\n"\
                                  "Equals nine squared and not a bit more.\n```")
                    event.respond("```\n81.\n```")
                    next
                end
                result = Dentaku(equation, pi: 3.14159265359)
                if [true, false].include? result then
                    event.respond("```\n#{result.to_s.capitalize}```\n")
                else
                    response = ( "%.15f" % result ).sub(/0*$/,"")
                    event.respond("```\n #{response} \n```")
                end
            rescue => error
                event.respond("**INTERNAL ERROR:** #{error.message}")
            end
        end

        def cmd_exit(event)
            break unless can_use?('exit', event)
            exit
        end

        def cmd_eval(event, *args)
            break unless can_use?('eval', event)
            event.bot.debug(Discordrb::Logger::FORMAT_BOLD + "WARNING USER "\
                            "#{event.user.name} JUST USED EVAL." + Discordrb::Logger::FORMAT_RESET)
            eval(args.join(' '))
        end
    end
end
