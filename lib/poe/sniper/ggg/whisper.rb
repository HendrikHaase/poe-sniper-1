module Poe
  module Sniper
    module Ggg
      class Whisper
        def initialize(whisper_string)
          @whisper_string = whisper_string
          @buyout = @whisper_string.match(/listed for [\d\.]+ [\S]+/).to_s.split(" ")[-2..-1]&.join(" ")
        end

        def to_s
          @whisper_string
        end

        def buyout?
          !@buyout.nil?
        end

        def buyout
          @buyout
        end
      end
    end
  end
end
