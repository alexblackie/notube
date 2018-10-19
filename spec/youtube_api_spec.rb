RSpec.describe Notube::YoutubeApi, :vcr do

  let(:service) do
    described_class.new(
      api_key: Notube::Application.settings.youtube_api_key
    )
  end

  describe "#get_channel" do
    let(:username) { nil }
    let(:id) { nil }
    subject { service.get_channel(username: username, id: id) }

    shared_examples "successful response" do
      it "fetches the channel and returns it", :aggregate_failures do
        expect(subject["id"]).to eq "UC8gFadPgK2r1ndqLI04Xvvw"
        expect(subject["snippet"]["title"]).to eq "Maangchi"
      end

      it "returns the uploads playlist id" do
        expect(subject["contentDetails"]["relatedPlaylists"]["uploads"]).to_not be_nil
      end

      it "returns branding images" do
        expect(subject["brandingSettings"]).to_not be_nil
      end
    end

    context "with a username" do
      let(:username) { "Maangchi" }
      it_behaves_like "successful response"
    end

    context "with an id" do
      let(:id) { "UC8gFadPgK2r1ndqLI04Xvvw" }
      it_behaves_like "successful response"
    end

    context "with a non-existent username" do
      let(:username) { "bonkbonkbonkasdfasdf" }
      it { is_expected.to be_nil }
    end

    context "with a non-existent ID" do
      let(:id) { "UCEEEEEEEEEEEEEEEEEEE" }
      it { is_expected.to be_nil }
    end

    context "without a username or id" do
      it "causes an error" do
        expect{ subject }.to raise_error(ArgumentError)
      end
    end

    context "with both a username and id" do
      let(:username) { "Maangchi" }
      let(:id) { "UC8gFadPgK2r1ndqLI04Xvvw" }

      it "causes an error" do
        expect{ subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#get_videos" do
    let(:channel) do
      Notube::Models::Channel.new(
        id: 123,
        url: "https://www.youtube.com/user/Maangchi",
        external_id: "UC8gFadPgK2r1ndqLI04Xvvw",
        playlist_id: "UU8gFadPgK2r1ndqLI04Xvvw"
      )
    end
    subject { service.get_videos(channel: channel) }

    it { is_expected.to be_an Array }

    it "returns 25 by default" do
      expect(subject.size).to eq 25
    end

    it "returns videos for the right channel" do
      channels = subject.map{|c| c["snippet"]["channelId"] }.uniq
      expect(channels).to eq ["UC8gFadPgK2r1ndqLI04Xvvw"]
    end
  end
end
