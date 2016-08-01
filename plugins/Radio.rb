#!/usr/bin/ruby

require 'thread'
require_relative '../lib/RadioBot.rb'

module Plugins
    class Radio
        def enable(bot)
            bot.command(:radio,
                         description: "It's a radio, for playing music.",
                         usage: "<add/pause/play/skip/replay/nowplaying/queue/enable/disable> [options]",
                         &method(:cmd_radio))

            bot.debug("Radio plugin enabled.")
        end

        def disable(bot)
            bot.remove_command(:radio)

            bot.debug("Radio plugin disabled")
        end

        private

        def cmd_radio(event, cmd, *args)
            break unless can_use?('radio', event)
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
    end
end
