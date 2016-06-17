#/usr/bin/ruby
require 'discordrb'
require 'fileutils'
require 'video_info'
require 'thread'

class RadioBot
    @@RadioBots = {}
    def initialize(bot, server)
        name = $config['radio_channel']
        server.channels.each do |channel|
            if channel.name == name and channel.type == "voice" then
                @channel = channel
                break
            end
        end
        if @channel == nil then
            raise "Invalid radio_channel name!"
        end
        @server = server
        @bot = bot;
        @bot.voice_connect(@channel)
        @voice = bot.voice(server)
        
        @queue = Queue.new
        @playing = nil
        @paused = false
        @running = true
        @@RadioBots[server] = self
        @songindex = 1
    end
    
    def addsong(url)
        begin
            video = VideoInfo.new(url)
            firstsong = @queue.empty?
            if video.available? and video.provider == "YouTube" then
                isplaylist = url.include?("playlist")
                info = {title: video.title, \
                        author: video.author, \
                        duration: video.duration, \
                        id: video.video_id, \
                        url: url, \
                        playlist: isplaylist }
                if firstsong then
                    dlsong(info)
                end
                @queue.push(info)
                
                return "OK"
            else
                return "ERROR"
            end
        rescue
            return "ERROR"
        end
    end
    
    def addplaylist(url) # DO NOT USE. BROKEN DO TO GOOGLE API BUG.
        begin
            playlistinfo = VideoInfo.new(url)
            numofvideos = 0
            if playlistinfo.available? and playlistinfo.provider == "YouTube" then
                numofvideos = playlistinfo.videos.length
                playlistinfo.videos.each do |info|
                    addsong("http://youtube.com/watch?v=#{info.video_id}")
                end
                return numofvideos
            else
                return -1
            end
        rescue => e
            puts e.message
            puts e.backtrace
            return -1
        end
    end

    def play
        if @paused == true then
            @paused = false
            @voice.continue
        end
    end
    
    def pause
        if @paused == false then
            @paused = true
            @voice.pause
        end
    end
    
    def close
        @running = false
        @queue.clear
        @playing = nil
        $bot.voice(@server).stop_playing
        @voice.destroy
        @@RadioBots[@server] = nil
        @@RadioBots.delete(@server)
    end
    
    def replay
        currentsong = @playing
        if currentsong == nil then
            return -1
        else
            $bot.voice(@server).stop_playing
            @queue.push(currentsong)
        end
    end
    
    def currentsong
        return @playing
    end
    
    def skip(num)
        toskip = num
        pause
        if toskip >= 1 and @playing != nil then
            @playing = nil
            $bot.voice(@server).stop_playing
            toskip -= 1
        end
        while toskip > 1 do
            unless @queue.empty? then
                @queue.pop(true)
            end
            toskip -= 1
        end
        play
    end
    
    def getqueue
        return @queue
    end
    
    def setqueue(queue)
        @queue = queue
    end
    
    def self.getbot(server)
        return @@RadioBots[server]
    end
    
    
    
    
    # PRIVATE
    
    def dlsong(info)

        Dir.foreach('videos') do |item|
            next if item == '.' or item == '..'
            if item.start_with?(info[:id]) then
                return
            end
        end
        command = "lib/youtube-dl --quiet --output 'videos/#{info[:id]}-%(autonumber)s.%(ext)s' --restrict-filenames --format 'worst' --extract-audio \"#{info[:url]}\""
        # --no-playlist
        system(command)

    end
    
    def dlnextsong
        if @queue.empty?
            return
        end
        nextsong = @queue.pop(true)
        @queue.push(nextsong)
        if nextsong == nil then
            return
        else
            t = Thread.new {
                dlsong(nextsong)
            }
        end
    end
    
    def run
        begin
            playlistindex = 1
            while @running do
                if @playing == nil and @queue.empty? then
                    sleep(1)
                    next
                elsif @playing == nil and (@queue.empty? == false) then
                    @playing = @queue.pop
                end
                audio_file = "#{@playing[:id]}-" + playlistindex.to_s.rjust(5, "0") + ".m4a"
                unless File.file?(File.expand_path("videos/#{audio_file}")) then
                    @playing = nil
                    playlistindex = 1
                    next
                end
                
                
                dlsong(@playing)
                dlnextsong
                
                # puts audio_file
                
                @voice.play_file(File.expand_path("videos/#{audio_file}"))
                
                playlistindex += 1
                
                # @playing = nil
                
                FileUtils.rm(File.expand_path("videos/#{audio_file}"))
                sleep(0.1)
            end
        rescue => e
            puts e.message
            puts e.backtrace
            puts 'error'
        end
        
        puts "Exiting"
    end
end