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
                    'server_name' => name, # Only for manual reading purposes
                    'roles' => 'default' => {'commands' => [
                    'about', 'choose', 'help', 'ping', 'random', 'calc'
                    ]},
                    'configured' => false
                }
            end
        end
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

    def self.can_use_command?(command, user, server_id)
        user.roles.each do |userrole|
            if role_has_access?(command, userrole.name, server_id) then
                return true
            end
        end
        return role_has_access?(command, 'default')
    end

    def self.role_has_access?(command, role, server_id) # I'm not proud of this, but it works, mostly.
        unless @@yamlconfig[server_id]['roles'][role] == nil
            if @@yamlconfig[server_id]['roles'][role]['commands'] != nil
                if (@@yamlconfig[server_id]['roles'][role]['commands'].include?(command) or @@yamlconfig[server_id]['roles'][role]['commands'].include?('all')) then
                    return true
                elsif @@yamlconfig[server_id]['roles'][role]['inherit'] != nil then
                    return role_has_access?(command, @@yamlconfig[server_id]['roles'][role]['inherit'])
                else
                    return false
                end
            elsif @@yamlconfig[server_id]['roles'][role]['inherit'] != nil then
                return role_has_access?(command, @@yamlconfig[server_id]['roles'][role]['inherit'])
            end
        end
            return false
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
        @@yamlconfig[@server_id]['roles'][role] = {'inherit' => superrole,
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
