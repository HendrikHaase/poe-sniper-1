require 'uri'

module Poe
  module Sniper
    module Ggg
      class UriHelper
        WS_URI = "wss://www.pathofexile.com/api/trade/live".freeze
        DETAILS_URI = "https://www.pathofexile.com/api/trade/fetch".freeze
  
        def self.live_ws_uri(search_url)
          URI.parse("#{WS_URI}/#{league(search_url)}/#{search_id(search_url)}")
        end

        def self.details_uri(live_ws, id)
          URI.parse("#{DETAILS_URI}/#{id}?query=#{live_ws.to_s.split("/").last}")
        end
  
      private
  
        def self.search_id(url)
          url = url[0..-2] if url.end_with?('/')
          parsed_url = URI.parse(url)
          path_parts = parsed_url.path.split '/'
          path_parts.last.eql?('live') ? path_parts[-2] : path_parts[-1]
        end

        def self.league(search_url)
          search_url.split("search/")[1].split("/")[0]
        end
      end
    end
  end
end
