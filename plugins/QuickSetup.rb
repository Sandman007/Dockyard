#!/usr/bin/ruby

module Plugins
    class QuickSetup
        def enable(bot)
            bot.command(:setup,
                         description: "Begins interactive setup of the bot.",
                         usage: "",
                         required_permissions: [:manage_server],
                         &method(:cmd_setup))

            bot.debug("QuickSetup plugin enabled.")
        end

        def disable(bot)
            bot.remove_command(:setup)

            bot.debug("QuickSetup plugin disabled.")
        end

        private

        def cmd_setup(event, subcommand, *args)
            setup = FritzServer.get(event.server).setup
            if setup == nil then
                event.respond("***Welcome to the Digital Express Setup Utility (DESU)***\n"\
                              "To begin guided setup, type `!setup begin` to start "\
                              "an interactive setup session. At anytime you may type "\
                              "`!setup cancel` to cancel the setup. Your changes "\
                              "will only be saved once DESU has finished.")
                FritzServer.get(event.server).setup_state = SetupConfiguration.new(event.user, event.server)
            else
                if setup.user != event.user then
                    event.respond("Sorry, a DESU session is already in progress on this server.")
                elsif subcommand == "begin" then
                    if setup.started?
                        event.respond("You have already started a DESU session.")
                    else
                        setup.start(event)
                    end
                elsif subcommand == "pass" then
                    unless setup.started?
                        event.respond("You have not started a DESU session.")
                    else
                        if setup.is_done? then
                            event.respond("DESU session canceled.")
                            FritzServer.get(event.server).setup_state = nil
                        else
                            setup.skip_step(event)
                        end
                    end
                elsif subcommand == "set" then
                    unless setup.started?
                        event.respond("You have not started a DESU session.")
                    else
                        setup.set(event, args)
                    end
                elsif subcommand == "confirm" then
                    unless setup.started?
                        event.respond("You have not started a DESU session.")
                    else
                        setup.confirm(event, args)
                    end
                elsif subcommand == "done" then
                    unless setup.started?
                        event.respond("You have not started a DESU session.")
                    else
                        setup.finish(event)
                        FritzServer.get(event.server).setup_state = nil
                    end
                elsif subcommand == "cancel"
                    FritzServer.get(event.server).setup_state = nil
                    event.respond("DESU session cancelled.")
                elsif subcommand == "help"
                    begin
                        commands = $config['predefined_roles'][args[0]]['commands']
                        if commands == nil
                            event.respond("Configuration error, #{args[0]} missing "
                            "`commands` section.")
                        else
                            event.respond("The #{args[0]} predefined role has "\
                                          "access to the following commands: "\
                                          "#{commands.join(", ")}.")
                        end
                    rescue => e
                        event.respond("That predefined role doesn't exist.")
                    end
                else
                    event.respond("That subcommand doesn't exist.")
                end
            end
        end

    end
end
