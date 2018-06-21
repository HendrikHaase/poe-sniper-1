require 'faye/websocket'
require 'net/http'
require 'permessage_deflate'

require_relative "uri_helper"
require_relative 'whisper'
require_relative '../alert'
require_relative '../analytics'
require_relative '../analytics_data'
require_relative '../logger'

module Poe
  module Sniper
    module Ggg
      class Socket
        attr_accessor :live_ws_uri, :search_name

        def initialize(live_ws_uri, search_name, alerts, ggg_session_id)
          @live_ws_uri = live_ws_uri
          @search_name = search_name
          @alerts = alerts
          @headers = {
            "Cookie" => "POESESSID=#{ggg_session_id}"
          }
        end

        def setup(keepalive_timeframe_seconds, retry_timeframe_seconds, reconnecting = false)
          ws = Faye::WebSocket::Client.new(@live_ws_uri.to_s, nil, headers: @headers, extensions: [PermessageDeflate])
          Logger.instance.info("Opening connection to #{get_log_url_signature}")

          ws.on :open do |event|
            log_connection_open(@live_ws_uri)
            Analytics.instance.track(event: 'Socket reopened', properties: AnalyticsData.socket_reopened(@live_ws_uri)) if reconnecting
          end

          ws.on :message do |event|
            Logger.instance.debug("Message received from #{get_log_url_signature}: #{event}")
            json = JsonHelper.parse(event.data)
            unless json.is_a?(Hash)
              Logger.instance.warn("Unexpected message format: #{json}")
            else
              json["new"].each do |id|
                Logger.instance.debug("New ID received: #{id}")

                response = Net::HTTP.get(UriHelper.details_uri(live_ws_uri, id))
                whisper = Whisper.new(JsonHelper.parse(response)["result"].first["listing"]["whisper"])
                @alerts.push(Alert.new(whisper, @search_name))
              end
            end
          end

          ws.on :close do |event|
            Analytics.instance.track(event: 'Socket closed', properties: AnalyticsData.socket_closed(@live_ws_uri, event)) unless reconnecting
            log_connection_close(event)

            # Reopen on close: https://stackoverflow.com/a/22997338/2771889
            sleep(retry_timeframe_seconds)
            log_connection_reconnect_attempt
            reconnecting = true
            setup(keepalive_timeframe_seconds, retry_timeframe_seconds, reconnecting)
          end

          ws
        end

        private

        def get_log_url_signature
          "#{@live_ws_uri} (#{@search_name})"
        end

        def log_connection_open(url)
          Logger.instance.info("Connected to #{url} (#{@search_name})")
        end

        def log_connection_close(event)
          message = (event.reason.nil? or event.reason.empty?) ? "no reason specified" : event.reason
          Logger.instance.warn("Connection closed to #{@live_ws_uri} (will try to reconnect) (code #{event.code}): #{message}")
        end

        def log_connection_reconnect_attempt
          Logger.instance.info("Trying to recconect to #{@live_ws_uri}")
        end
      end
    end
  end
end
