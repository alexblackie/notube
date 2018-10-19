RSpec.describe Notube::Database do

  let(:model) { Notube::Models::Video }

  # SQLite doesn't allow multiple connections, so we need to use the application
  # instance as it is booted already for the test suite.
  let(:service) { Notube::Application.settings.db }

  describe "#find" do
    subject { service.find(model, id) }

    context "with an existing record" do
      let(:id) { service.db.last_insert_row_id }

      before do
        service.execute("insert into videos (title) values (?)", "test video")
      end

      it "finds the right record" do
        expect(subject.title).to eq "test video"
      end

      it "instantiates a model" do
        expect(subject).to be_a model
      end
    end

    context "when a record is not found" do
      let(:id) { "wat" }
      it { is_expected.to be_nil }
    end
  end

  describe "#find_by" do
    subject { service.find_by(model, attrs) }

    context "when a record exists" do
      before do
        service.execute("insert into videos (external_id, title) values (?, ?)", ["xxx123", "piglets rolling in flowers"])
      end

      let(:attrs) {{ external_id: "xxx123" }}

      it { is_expected.to be_a model }

      it "is the correct record" do
        expect(subject.title).to eq "piglets rolling in flowers"
      end
    end

    context "when a record cannot be found" do
      let(:attrs) {{ external_id: "bazoingle" }}
      it { is_expected.to be_nil }
    end
  end

  describe "#execute" do
    it "allows arbitrary queries" do
      expect(service.execute("select 'got em'")).to eq [["got em"]]
    end
  end

end
