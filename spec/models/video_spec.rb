RSpec.describe Notube::Models::Video do

  let(:video) do
    described_class.new({
      title: "cat falls off bathtub",
      description: "lmao rofl",
      published_at: "2018-10-04T10:02:00Z"
    })
  end

  describe "#watched?" do
    subject { video.watched? }

    context "when watched_at is set" do
      before do
        video.watched_at = DateTime.now
      end

      it { is_expected.to be_truthy }
    end

    context "when watched_at is not set" do
      before do
        video.watched_at = nil
      end

      it { is_expected.to be_falsey }
    end
  end

  describe "#downloaded?" do
    subject { video.downloaded? }

    context "when watched_at is set" do
      before do
        video.downloaded_at = DateTime.now
      end

      it { is_expected.to be_truthy }
    end

    context "when watched_at is not set" do
      before do
        video.downloaded_at = nil
      end

      it { is_expected.to be_falsey }
    end
  end
end
