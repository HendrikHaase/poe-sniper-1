require 'spec_helper'

RSpec.describe Poe::Sniper::Ggg::UriHelper do
  describe ".league" do
    it { expect(described_class.league("https://www.pathofexile.com/trade/search/Incursion/NK6Ec5")).to eq("Incursion") }
    it { expect(described_class.league("https://www.pathofexile.com/trade/search/Incursion/NK6Ec5/")).to eq("Incursion") }
    it { expect(described_class.league("https://www.pathofexile.com/trade/search/Incursion/NK6Ec5/live")).to eq("Incursion") }
    it { expect(described_class.league("https://www.pathofexile.com/trade/search/Incursion/NK6Ec5/live/")).to eq("Incursion") }
  end

  describe ".details_uri" do
    it { expect(described_class.details_uri(URI.parse("wss://www.pathofexile.com/api/trade/live/Incursion/NK6Ec5"), "772705ab961b79f49ff617ef1aece10ab152b90823cf3c80dd6a1e80bf73fe1b"))
      .to eq(URI.parse("https://www.pathofexile.com/api/trade/fetch/772705ab961b79f49ff617ef1aece10ab152b90823cf3c80dd6a1e80bf73fe1b?query=NK6Ec5")) }
  end
end
