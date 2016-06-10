#!/usr/bin/ruby

# Simple monkey-patch to fix the 'usage' section of the error messages
module Discordrb::Commands
    class Command
        def call(event, arguments, chained = false)
            if arguments.length < @attributes[:min_args]
              event.respond "Too few arguments for command `#{name}`!"
              event.respond "Usage: `!#{name} #{@attributes[:usage]}`" if @attributes[:usage]
              return
            end
            if @attributes[:max_args] >= 0 && arguments.length > @attributes[:max_args]
              event.respond "Too many arguments for command `#{name}`!"
              event.respond "Usage: `!#{name} #{@attributes[:usage]}`" if @attributes[:usage]
              return
            end
            unless @attributes[:chain_usable]
              if chained
                event.respond "Command `#{name}` cannot be used in a command chain!"
                return
              end
            end

            rate_limited = event.bot.rate_limited?(@attributes[:bucket], event.author)
            if @attributes[:bucket] && rate_limited
              if @attributes[:rate_limit_message]
                event.respond @attributes[:rate_limit_message].gsub('%time%', rate_limited.round(2).to_s)
              end
              return
            end

            @block.call(event, *arguments)
            rescue LocalJumpError # occurs when breaking
                nil
        end
    end
end
  


