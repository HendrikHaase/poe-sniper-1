require 'faye/websocket'
require 'json'
require 'net/http'

require_relative 'whisper'
require_relative 'alert'

class Sockets

  def initialize(alerts)
    @sockets = []
    @alerts = alerts
  end

  def socket_setup(search_url, live_url, search_name)
    ws = Faye::WebSocket::Client.new(live_url)
    @sockets.push(ws)

    ws.on :open do |event|
      ws.send '{"type": "version", "value": 3}'
      ws.send 'ping'
    end

    ws.on :message do |event|
      json = JSON.parse(event.data)
      case json['type']
        when 'pong'
          p "connected to: #{live_url}"
        when 'notify'
          id = json['value']
          response = Net::HTTP.post_form(search_url, 'id' => id)
          response_data = JSON.parse(response.body)
          whispers = PoeTradeParser.get_whispers(response_data['data'], response_data['uniqs'])
          whispers.each do |whisper|
            @alerts.push(Alert.new(whisper, search_name))
          end
        else
          p "WARNING: Unknown event type: #{json['type']}"
      end
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end

end