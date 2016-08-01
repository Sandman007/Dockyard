#!/usr/bin/ruby

require 'yaml'

module Plugins
    class PermissionSet
        def enable(bot)
            bot.command(:pcs,
                        min_args: 1,
                        description: "Permission & configuration utility",
                        usage: "[subcommand] <args>",
                        &method(:cmd_pcs))

            bot.debug("PermissionSet plugin enabled")
        end

        def disable(bot)
            bot.remove_command(:pcs)

            bot.debug("PermissionSet plugin disabled")
        end

        private

        def cmd_pcs(event, subcommand, *args)
            break unless can_use?('pcs', event)

            case subcommand
            when 'role'
                role_cmd(event, args)
            when 'user'
                handleUserCmd(event, args)
            else
                print_global_help(event)
            end
        end

        def print_global_help(event)
            event.respond("Usage: [subcommand] <args>\n"\
                          "Possible subcommands are:\n"\
                          "`help`\n"\
                          "`role [rolename] [action] <args>`\n"\
                          "`user [username] [action] <args>`\n"\
                          "Type `[subcommand] help` for help for a "\
                          "specific subcommand.")
        end

        def role_cmd(event, args)
            return unless can_use('pcs.role', event)

            if args[0] == 'help' then
                print_role_help(event)
                return
            end
            role = FritzServer.get(event.server)[args[0].downcase]
            unless role then
                event.respond("Couldn't find that role. Please type roles "\
                              "*full* name.")
                return
            end
            case args[1]
            when 'list'
                role_list_cmd(event, role, args[2..99])
            when 'add-permission'
                role_addpermission(event, role, args[2])
            when 'remove-permission'
                role_removepermission(event, role, args[2])
            when 'set'
                role_setproperty(event, role, args[2], args[3..99].join(' '))
            else
                print_role_help(event)
            end
        end

        def role_list_cmd(event, role, args)
            return unless can_use?('pcs.role.list', event)


            serv = FritzServer.get(event.server)

            case args[0]
            when 'permissions'
                event.respond("Role #{role.name}'s permissions:\n"\
                              + serv.get_configuration\
                                    ['roles'][role.name]\
                                    ['commands'].join(', '))
            when 'options'
                options = serv.get_configuration['roles'][role.name]['options']\
                              .to_yaml.sub('---', '').lstrip
                event.respond("Role #{role.name}'s options:\n"
                              "```\n#{options}\n```")
            else
                event.respond("Usage:\n"\
                              "`[role] list permissions` ")
            end

        end

    end
end
