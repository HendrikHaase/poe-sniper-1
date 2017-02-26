require 'faye/websocket'
require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'rb-notifu'
require 'win32/clipboard' #gem install win32-clipboard
include Win32

NOTIFICATION_SECONDS = 10

uri = URI.parse("http://poe.trade/search/aasitahouokaka/live")

def socket
  EM.run {
    ws = Faye::WebSocket::Client.new('ws://live.poe.trade/aasitahouokaka')

    ws.on :open do |event|
      p [:open]
      ws.send '{"type": "version", "value": 3}'
      ws.send 'ping'
    end

    ws.on :message do |event|
      json = JSON.parse(event.data)
      p json
      case json['type']
        when 'pong'
          p 'connection up'
        when 'notify'
          id = json['value']
          res = Net::HTTP.post_form(uri, 'id' => id)
          # puts res.body
          parse_socket_data_json(res.body)
        # html = Nokogiri::HTML(res.body['data'])
        # p html

      end
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  }
end


def parse_socket_data_json(socket_data)
  get_whispers(socket_data['data'], socket_data['uniqs'])
end

def get_whispers(html_item_data, ids)
  whispers = []
  html = Nokogiri::HTML(html_item_data)

  ids.each do |id|
    data_path = "tbody.item-live-#{id}"
    whispers << get_whisper(get_html_data_attributes(get_html_element_by_path(html, data_path)))
  end

  whispers
end

def get_html_element_by_path(html, path)
  html.css(path)[0]
end

def get_html_data_attributes(tbody)
  data = {}
  data_attributes = tbody.xpath("./@*[starts-with(name(), 'data-')]") # . relative path
  data_attributes.each { |x| data[x.name] = x.value }
  data
end

def get_whisper(data)
  greeting = "@#{data['data-ign']} Hi, I would like to buy your "
  item = data['data-name']
  buyout = data['data-buyout'].empty? ? '' : " listed for #{data['data-buyout']}"
  league = " in #{data['data-league']}"
  location = data['data-tab'].empty? ? '' : get_item_location(data)

  greeting + item + buyout + league + location
end

def get_item_location(data)
  message = " (stash tab #{data['data-tab']}"
  x = data['data-x'].to_i
  y = data['data-y'].to_i
  if x >= 0 and y >= 0
    message += "; position: left #{x+1}, top #{y+1})"
  end
  message
end

def alert(whispers)
  cnt = whispers.length
  whispers.each do |whisper|
    title = 'New item listed'
    title += " (#{cnt -1} more)" if cnt > 1
    notification_thread = show_notification(title, whisper)
    set_clipboard(whisper)
    # TODO replace with wait until gem
    while ['run', 'sleep'].include? notification_thread.status
      sleep 0.1
    end
    cnt -= 1
  end
end

def show_notification title, message
  Notifu::show :title => title, :message => message, :type => :info, :time => NOTIFICATION_SECONDS, :noquiet => true
end

def set_clipboard message
  Clipboard.set_data(message, format = Clipboard::UNICODETEXT) # unicode for russian characters
end

whispers = parse_socket_data_json(JSON.parse(File.open('example_socket_data.json').read))

alert whispers[0..5]
