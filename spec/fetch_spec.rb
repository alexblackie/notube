RSpec.describe Notube::Fetch, :vcr do

  let(:service) { described_class.new }
  let(:db) { Notube::Application.settings.db }

  describe "#add_channel" do
    let(:url) { "https://www.youtube.com/user/Perfume" }
    subject { service.add_channel(url) }

    it { is_expected.to be_a Notube::Models::Channel }

    it "downloads the banner and thumbnail" do
      expect(service).to receive(:download_image).twice()
      subject
    end

    it "adds the channel to the database" do
      query = -> { db.execute("select count(1) from channels where url = ?", url) }
      expect{ subject }.to change{ query.call }.to [[1]]
    end

    context "when a channel already exists" do
      before do
        db.execute("insert into channels (external_id, url) values (?, ?)", ["UCxOjoraUPd0Dq9PAyIhC6tQ", url])
      end

      it { is_expected.to be_a Notube::Models::Channel }

      it "does not call the API" do
        expect_any_instance_of(Notube::YoutubeApi).to_not receive :get_channel
        subject
      end
    end

    context "when the channel is not found" do
      let(:url) { "https://www.youtube.com/user/asdfasdfadsfasdfasdfasdfasdf99999" }

      it { is_expected.to be_nil }
    end

  end

  describe "#add_videos_for_channel" do
    let(:channel) do
    end
    subject { service.add_videos_for_channel(channel) }

    it "creates video records" do
    end

  end

end
