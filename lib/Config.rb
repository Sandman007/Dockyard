#!/usr/bin/ruby

require 'yaml'
require 'yaml/store'

class Config
    def initialize(file = "config.yaml")
        @file = file
        @yamlconfig = YAML.load_file(file)
    end

    def [](key)
        return @yamlconfig[key]
    end

    def []=(key, value)
        @yamlconfig[key] = value
    end

    def print
        puts @yamlconfig
    end

    def save
        store = YAML::Store.new(@file)
        store.transaction do
            @yamlconfig.each do |k, v|
                store[k] = v
            end
        end
    end
end


class Permissions
    def initialize(server_id, name, file = "permissions.yaml")
        unless server_id and name
            @@file = file
            @@yamlconfig = YAML.load_file(file)
        else
            @server_id = server_id
            if @@yamlconfig[server_id] == nil
                @@yamlconfig[server_id] = { # Default configuration
                    'server_name' => name,  # Only for manual reading purposes
                    'roles' => 'default' => {
                    'options' => {
                        'power' => 0
                    },
                    'commands' => [
                        'about', 'choose', 'help', 'ping', 'random', 'calc'
                    ]}}
                @isnew = true
            else
                @isnew = false
            end
        end
    end

    def isnew
        return @isnew
    end

    def self.reload
        @@yamlconfig = YAML.load_file(@@file)
    end

    def self.save
        store = YAML::Store.new(@@file)
        store.transaction do
            @@yamlconfig.each do |k, v|
                store[k] = v
            end
        end
    end

    def self.user_has_permission?(command, user, server_id)
        user.roles.each do |userrole|
            if role_has_permission?(command, userrole.name, server_id) then
                return true
            end
        end
        return false
    end

    def self.role_has_permission?(permission_in, role, server_id)
        permissions = @@yamlconfig[server_id]['roles'][role]['commands']
        permissions.each do |perm|
            result = true
            if perm.start_with?('-') then
                perm.sub!('-', '')
                result = false
            end
            if compare_permission(permission_in, perm) then
                return result
            end
        end
        return false if role == 'default'
        inherit = @@yamlconfig[server_id]['roles'][role]['options']['inherit'] || 'default'
        return role_has_permission(permission_in, inherit, server_id)
    end

    # If recursive version prooves to cause issues, use this instead.
    # Should be fine though.
    # def self.role_has_permission?(permission, role, server_id)
    #     checked_default = false
    #     while true
    #         if role == 'default'
    #             checked_default = true
    #         end
    #         permissions = @@yamlconfig[server_id]['roles'][role]['commands']
    #         permissions.each do |perm|
    #             result = true
    #             if perm.start_with?('-') then
    #                 perm.sub!('-', '')
    #                 result = false
    #             end
    #             if compare_permission(permission, perm) then
    #                 return result
    #             end
    #         end
    #         role = @@yamlconfig[server_id]['roles'][role]['options']['inherit']
    #         unless role and (!checked_default)
    #             role = 'default'
    #         end
    #     end
    #     return false
    # end

    def self.compare_permission(str1, str2)
        perm1 = str1.split('.')
        compare_to = str2.split('.')
        compare_to.split('.').each_with_index do |perm, index|
            if index == perm1.length
                return true
            elsif perm == '*'
                return true
            elsif perm != perm1[index]
                return false
            end
        end
    end

    def self.is_restricted?(permission)
        $config['restricted_permissions'].each do |perm|
            if compare_permission(permission, perm) then
                return true
            end
        end
        return false
    end

    def self.can_use_restricted?(user)
        $config['user_whitelist'].each do |username|
            if "#{user.username}##{user.tag}" == username
                return true
            end
        end
        return false
    end

    def role_inherits?(below, above)
        currentrole = above
        while currentrole
            if currentrole == below then
                return true
            end
            currentrole = @@yamlconfig[@server_id]['roles'][currentrole]['options']['inherit']
        end
        return false
    end

    def self.configuration_options
        # TODO
    end

    def [](key)
        return @@yamlconfig[@server_id][key]
    end

    def []=(key, value)
        @@yamlconfig[@server_id][key] = value
    end

    def add_command_to_role(command, role)
        if @@yamlconfig[@server_id]['roles'][role] == nil then
            @@yamlconfig[@server_id]['roles'][role] = {'commands' => [command]}
            # @yamlconfig[server_id]['roles'][role]['commands'] = Array.new(command)
        else
            @@yamlconfig[@server_id]['roles'][role]['commands'].insert(command)
        end
    end

    def remove_command_from_role(command, role)
        unless @@yamlconfig[@server_id]['roles'][role] == nil then
            @@yamlconfig[@server_id]['roles'][role]['commands'] - [command]
        end
    end

    def add_role(role, superrole)
        @@yamlconfig[@server_id]['roles'][role] = {'options' => { 'inherit' => superrole},
                                                   'commands' => []}
    end

    def remove_role(role)
        @@yamlconfig[@server_id]['roles'].delete(role)
    end

    def get_role_data(role)
        return @@yamlconfig[@server_id]['roles'][role]
    end

    def set_role_data(role, data)
        @@yamlconfig[@server_id]['roles'][role] = data
    end

end

class SetupConfiguration
    def initialize(user, server)
        @userid = user
        @server = server
        @configuration = {}
        @fritzserver = FritzServer.get(server)
        @begun = false
    end

    def user
        return @user
    end

    def server
        return @server
    end

    def set_config(key, value)
        @configuration[key] = value
    end

    def start(event)
        @begun = true
        config_default_channel(event.channel)
    end

    def started?
        return @begun
    end

    def is_done?
        if @configstep == :finish
            return true
        else
            return false
        end
    end

    def next_step(event)
        case @configstep
        when :default_channel
            config_radio_channel(event.channel)
        when :radio_channel
            config_roles(event.channel)
        end
    end

    def set(event, args)
        if @configstep == :default_channel then
            if _default_channel_setup(event, args) == :fail then
                return
            end
        elsif @configstep == :radio_channel then
            if _radio_channel_setup(event, args) == :fail then
                return
            end
        elsif @configstep == :roles then
            _roles_setup(event, args)
            return
        end
        next_step(event)
    end

    def finish(event)
        if @configstep != :finish then
            event.respond("You cannot save the configuration yet.")
            return
        end
        if @configuration[:default_channel] then
            @fritzserver.get_configuration['default_channel'] = @configuration[:default_channel]
        end
        if @configuration[:radio_channel] then
            @fritzserver.get_configuration['radio_channel'] = @configuration[:radio_channel]
        end
        if @configuration[:roles] then
            @configuration[:roles].each do |key, value|
                commands    = $config['predefined_roles'][key.downcase]['commands']
                inheritraw  = $config['predefined_roles'][key.downcase]['options']['inherit']
                inherit     = @configuration[inheritraw.downcase] || inheritraw
                options     = $config['predefined_roles'][key.downcase]['options']
                if options['inherit']
                    options['inherit'] = inherit
                end
                data = {'options' => options, 'commands' => commands}
                @fritzserver.get_configuration.set_role_data(value, data)
            end
        end
        event.respond("Configuration saved. Thanks for using DESU, the leading "\
                      "industry standard configuration setup system for Fritz "\
                      "Servers.")
    end

    def confirm(event, args)
        if @configstep == :roles then
            event.respond("This concludes your DESU session. To save the "\
                          "configuration, type `!setup done`, or if you wish "\
                          "to cancel this DESU session, type `!setup pass`.")
            @configstep = :finish
        end
    end

    def config_default_channel(channel)
        channel.send_message("To set the bots default text channel, please "\
                             "send `!setup set` in the channel you wish to be "\
                             "the bots default channel, or if you wish to "\
                             "keep the current setting, type `!setup pass`")
        @configstep = :default_channel
    end

    def config_radio_channel(channel)
        channel.send_message("To set the Radio channel, please enter "\
                             "`!setup set [channel name]`. If you wish to "\
                             "keep the current setting, type `!setup pass`")
        @configstep = :radio_channel
    end

    def config_roles(channel)
        channel.send_message("In this step you will perform a basic assignment "\
                             "of server roles to predefined bot roles. The "\
                             "predefined bot roles are as follows: SuperAdmin, "\
                             "Admin, Moderator, and Member. To view the commands "\
                             "each of these roles give access to, type "\
                             "`!setup help <predefined role name>`. To set a "\
                             "server role to a predefined bot role, type "\
                             "`!setup set [server role], [predefined bot role]`. "\
                             "Once finished, simply type `!setup confirm`."\
                             "You may now type `!setup pass` to skip this step "\
                             "and if desired, manually configure bot roles with "\
                             "`!config` after setup has finished.")
        @configuration[:roles] = {}
        @configstep = :roles
    end

    def _default_channel_setup(event, args)
        if args.empty? then
            @configuration[:default_channel] = event.channel.id
        else
            channel = $bot.find_channel(args.join(" "), event.server.name, 'text')
            if channel.empty? then
                event.respond("No text channels by the name where found. "\
                              "Did you spell it correctly? Please try again.")
                return :fail
            elsif channel.length > 1 then
                event.respond("Multiple text channels by the name where found. "\
                              "Please be more precise with the name.")
                return :fail
            else
                @configuration[:default_channel] = channel.id
            end
        end
    end

    def _radio_channel_setup(event, args)
        if args.empty? then
            event.respond("Please reply with channel name.")
            return :fail
        else
            channel = $bot.find_channel(args.join(" "), event.server.name, 'voice')
            if channel.empty? then
                event.respond("No voice channels by the name where found. "\
                              "Did you spell it correctly? Please try again.")
                return :fail
            elsif channel.length > 1 then
                event.respond("Multiple voice channels by the name where found. "\
                              "Please be more precise with the name.")
                return :fail
            else
                @configuration[:radio_channel] = channel.id
            end
        end
    end

    def _roles_setup(event, args)
        if args.empty? then
            event.respond("Please reply with [server role], [bot role]".)
            return :fail
        else
            serverrole = @fritzserver[args.join(" ").split(", ")[0]]
            botrole    = args.join(" ").split(", ")[1]
            if serverrole == nil then
                event.respond("Unable to find that server role, please use FULL "\
                              "name and note that it is case sensitive.")
                return :fail
            elsif ['superadmin', 'admin', 'moderator', 'member'].include?(botrole.downcase) == false then
                event.respond("That predefined role does not exist.")
                return :fail
            else
                if @configuration[:roles][botrole.downcase] then
                    event.respond("Warning, you just redefined which server role "\
                                  "#{botrole.downcase} is assigned too.")
                end
                @configuration[:roles][botrole.downcase] = serverrole.name
                event.respond("Added.")
            end
        end
    end
end
