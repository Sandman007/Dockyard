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
    
    def delete_region(region)
        @yamlconfig["regions"].delete_if { |x| x == region }
    end
    
    def add_region(region)
        @yamlconfig["regions"].push(region)
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
    def initialize(file = "permissions.yaml")
        @file = file
        @yamlconfig = YAML.load_file(file)
    end
    
    def save
        store = YAML::Store.new(@file)
        store.transaction do
            store["roles"] = @yamlconfig["roles"]
        end
    end
    
    def can_use_command?(command, user)
        user.roles.each do |userrole|
            if role_has_access?(command, userrole.name) then
                return true
            end
        end
        return role_has_access?(command, 'default')
    end
    
    def role_has_access?(command, role) # I'm not proud of this, but it works, mostly.
        unless @yamlconfig['roles'][role] == nil
            if @yamlconfig['roles'][role]['commands'] != nil
                if (@yamlconfig['roles'][role]['commands'].include?(command) or @yamlconfig['roles'][role]['commands'].include?('all')) then
                    return true
                elsif @yamlconfig['roles'][role]['inherit'] != nil then
                    return role_has_access?(command, @yamlconfig['roles'][role]['inherit'])
                else
                    return false
                end
            elsif @yamlconfig['roles'][role]['inherit'] != nil then
                return role_has_access?(command, @yamlconfig['roles'][role]['inherit'])
            end
        end
            return false
    end
    
    def add_command_to_role(command, role)
        if @yamlconfig['roles'][role] == nil then
            @yamlconfig['roles'][role] = {"commands" => [command]}
            # @yamlconfig['roles'][role]['commands'] = Array.new(command)
        else
            @yamlconfig['roles'][role]['commands'].insert(command)
        end
    end
    
    def remove_command_from_role(command, role)
        unless @yamlconfig['roles'][role] == nil then
            @yamlconfig['roles'][role]['commands'] - [command]
        end
    end
end
