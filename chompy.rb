require 'rubygems'
require 'hipchat-api'
require 'time'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'pry'
require 'pry-nav'


class Chompy
  POLLING_FREQUENCY = 5

  # Stores list of plugins
  @@plugins

  attr_accessor :api, 
                :room, 
                :stop_poll, 
                :last_updated_at,
                :api_key

  def initialize(api_key)
    self.api_key = api_key
  end

  # Begin the chompiness
  def chomp(room_name)
    self.api = HipChat::API.new(api_key)
    api.set_timeout(15)
    self.room = api.rooms_list['rooms'].detect{|r| r['name'].eql?(room_name) }
    
    begin_polling and return if room
    raise 'RoomNotFound'
  end

  def stop_poll?
    stop_poll
  end

  # Send a message to the chat room
  def chat(msg, type='text')
    api.rooms_message(room['room_id'], 'Chompy', msg, 0, nil, type)
  end

  # Send image chat
  # Optional link parameter to link to original image
  def image_chat(src, link=nil)
    message = "<img src=\"#{src}\" />"
    if link
      message = "<a href=#{link}>#{message}</a>"
    end
    chat(message, 'html')
  end

  def self.register_plugin(klass)
    @@plugins ||= []
    @@plugins << klass
    include klass
  end

  protected

  def retrieve_new_messages
    puts '===================================='
    message_history = api.rooms_history(room['room_id'], 'recent', 'UTC')
    current_time = Time.now

    # The first run-through is just setting the last message date so
    # we have something to compare
    unless self.last_updated_at
      self.last_updated_at = Time.parse(message_history['messages'].last['date'])
    end

    last_msg_time = Time.parse(message_history['messages'].last['date'])

    puts "Last message time: #{last_msg_time}"
    puts "Last updated at: #{last_updated_at}"
    puts last_msg_time > last_updated_at

    new_messages = message_history['messages'].select do |message|
      Time.parse(message['date']) > last_updated_at
    end
    self.last_updated_at = last_msg_time

    puts new_messages.length

    parse_messages(new_messages)
  end

  def parse_messages(messages)
    puts 'parsing messages'
    messages.each do |message|
      text = message['message'].downcase
      next unless text =~ /^\(chompy\)/

      chat_hook(text)

      case text
      when /die/
        chat('Goodbye')
        self.stop_poll = true
      end
    end
  end

  # Invokes plugins with chat messages
  # so they can respond appropriately
  def chat_hook(text)
    @@plugins.each do |plugin|
      plugin.chat(text)
    end
  end

  # Kick off a poller to grab new messages
  def begin_polling
    self.stop_poll = false
    poll do
      retrieve_new_messages
    end
  end

  # Runs a block every X seconds until told to stop
  def poll(frequency = POLLING_FREQUENCY)
    start_time = Time.now
    loop do
      break if stop_poll?
      sleep 1
      if Time.now - start_time >= frequency
        yield
        start_time = Time.now
      end
    end
  end

end

chompy = Chompy.new('48b2b26956a7874559c6d80ef85f80')
chompy.chomp('Tailorwell Dev Chat')
