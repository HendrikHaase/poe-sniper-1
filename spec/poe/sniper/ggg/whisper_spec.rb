require 'spec_helper'

RSpec.describe Poe::Sniper::Ggg::Whisper do
  describe "#to_s" do
    it "returns string given during initialization" do
      expect(described_class.new("bla").to_s).to eq("bla")
    end
  end

  describe "#buyout" do
    it "returns buyout price if whisper contains one" do
      expect(described_class.new("bla listed for 2.5 chaos bla").buyout).to eq("2.5 chaos")
    end

    it "returns nil if whisper doesn't contain buyout price" do
      expect(described_class.new("bla bla").buyout).to be_nil
    end
  end

  describe "#buyout?" do
    it "returns truthy if whisper contains buyout price" do
      expect(described_class.new("bla listed for 2.5 chaos bla").buyout?).to be_truthy
    end

    it "returns falsey if whisper doesn't contain buyout price" do
      expect(described_class.new("bla bla").buyout?).to be_falsey
    end
  end
end
