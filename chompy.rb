require 'rubygems'
require 'hipchat-api'
require 'time'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'


class Chompy
  POLLING_FREQUENCY = 5

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

      case text
      when /showme(.*)$/
        image_search($1.strip)
      when /goto(.*)$/
        switch_room($1.strip)
      when /die/
        chat('Goodbye')
        self.stop_poll = true
      end
    end
  end

  def switch_room(name)
    new_room = api.rooms_list['rooms'].detect{|r| r['name'].downcase.eql?(name) }
    if new_room
      self.room = new_room
      self.last_updated_at = nil
      chat("I is here!")
    else 
      chat('Room not found')
    end
  end

  def image_search(search_text)
    puts "Image searching: #{search_text}"

    url = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=#{CGI::escape(search_text)}"
    uri = URI.parse(url)

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri, {
        'Referer' => 'http://tailorwell.com'
      })
      response = http.request(request)

      results = JSON.load(response.body)
      img = results['responseData']['results'].first
      image_chat(img['tbUrl'], img['originalContextUrl'])      
    rescue
      chat('search failed')
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

chompy = Chompy.new('API_KEY')
chompy.chomp('Tailorwell Dev Chat')
