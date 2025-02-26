require 'rails_helper'

RSpec.describe CampaignUpdaterService do
  let(:platform) { create(:platform) }
  let(:advertiser) { create(:advertiser, platform: platform) }
  let(:campaign) { create(:campaign, platform: platform, advertiser: advertiser, status: 'open') }
  let(:campaign_api) { double("CampaignApi") }
  let(:platform_api) { double("PlatformApi", campaign_api: campaign_api) }
  let(:valid_attributes) {
    ActionController::Parameters.new({
      title: "Updated Campaign",
      advertiser_id: advertiser.id,
      budget_cents: 5000,
      currency: "USD",
      status: "open",
      platform_id: platform.id,
      platform_campaign_id: campaign.platform_campaign_id
    }).permit!
  }
  let(:invalid_attributes) {
    ActionController::Parameters.new({
      title: "",
      advertiser_id: nil,
      budget_cents: nil,
      currency: "",
      status: "open"
    }).permit!
  }
  let(:subject) { described_class.new(platform, campaign, platform_api, valid_attributes) }

  before do
    allow(campaign_api).to receive(:get).and_return(campaign)
    allow(campaign_api).to receive(:create).and_return(double(id: 123))
    allow(campaign_api).to receive(:update).and_return(true)
    allow(campaign_api).to receive(:delete).and_return(true)
  end

  describe "PUT #update" do
    context "when campaign has no changes" do
      let(:subject) { described_class.new(platform, campaign, platform_api, valid_attributes) }

      before do
        allow(subject).to receive(:are_campaigns_same_content?).and_return(true)
      end

      it "redirects with a notice" do
        result = subject.action

        expect(result).to eq({
          status: :success,
          action: :notice,
          message: "Campaign no changes"
        })
      end
    end

    context "with valid attributes" do
      let(:subject) { described_class.new(platform, campaign, platform_api, valid_attributes) }

      it "updates the campaign and redirects" do
        result = subject.action

        campaign.reload
        expect(campaign.title).to eq("Updated Campaign")
        expect(result).to eq({
          status: :success,
          action: :notice,
          message: "Update the campaign successfully"
        })
      end
    end

    context "with archived campaign " do
      let(:status_no_changes_attributes) { valid_attributes.merge({status: "archive"}) }
      let(:subject) { described_class.new(platform, campaign, platform_api, status_no_changes_attributes) }

      before do
        campaign.update!(status: "archive")
      end

      it "updates the campaign and redirects" do

        result = subject.action

        campaign.reload
        expect(campaign.title).to eq("Updated Campaign")
        expect(result).to eq({
          status: :success,
          action: :notice,
          message: "Update the campaign successfully"
        })
      end
    end

    context "with invalid attributes" do
      let(:subject) { described_class.new(platform, campaign, platform_api, invalid_attributes) }

      it "does not update and redirects with alert" do
        result = subject.action

        expect(result).to eq({
          status: :failed,
          action: :alert,
          message: "Failed to update campaign."
        })
      end
    end

    context "when platform's campaign is newer" do
      before do
        platform_campaign_stub = double(
          id: campaign.platform_campaign_id,
          title: "New Title", 
          budget_cents: 10000, 
          currency: "USD",
          advertiser_id: advertiser.platform_advertiser_id,
          updated_at: Time.zone.now
        )
        allow(campaign_api).to receive(:get).and_return(platform_campaign_stub)
        allow(campaign_api).to receive(:create).and_return(double(id: "new-platform-campaign-id"))
        allow(campaign_api).to receive(:update).and_return(true)
        allow(campaign_api).to receive(:delete).and_return(true)
    
        allow_any_instance_of(Campaign).to receive(:updated_at).and_return(1.day.ago)
        allow(subject).to receive(:are_campaigns_same_content?).and_return(false)
      end
    
      it "cancels update and redirects with an alert" do
        result = subject.action

        expect(result).to eq({
          status: :success,
          action: :alert,
          message: "Cancel the update, due to data updates on the platform"
        })
      end
    end
    
    context "when status changes" do
      before do
        platform_campaign_stub = double(
          id: campaign.platform_campaign_id,
          title: "New Title",
          budget_cents: 10000,
          currency: "USD",
          advertiser_id: advertiser.platform_advertiser_id,
          updated_at: Time.zone.now
        )

        allow(campaign_api).to receive(:get).and_return(platform_campaign_stub)
        allow(campaign_api).to receive(:create).and_return(double(id: "new-platform-campaign-id"))
        allow(campaign_api).to receive(:delete).and_return(true)
      end

      it "updates to open and creates platform campaign" do
        campaign.update!(status: "archive")

        subject = described_class.new(platform, campaign, platform_api, valid_attributes.merge(status: "open"))
        result = subject.action

        campaign.reload
        expect(campaign.status).to eq("open")
        expect(campaign.platform_campaign_id).to eq("new-platform-campaign-id")
        expect(result).to eq({
          status: :success,
          action: :notice,
          message: "Update campaign successfully"
        })
      end

      it "updates to archive and deletes platform campaign" do
        campaign.update!(status: "open")

        subject = described_class.new(platform, campaign, platform_api, valid_attributes.merge(status: "archive"))
        result = subject.action

        campaign.reload
        expect(campaign.status).to eq("archive")
        expect(result).to eq({
          status: :success,
          action: :notice,
          message: "Update campaign successfully"
        })
      end

      it "rejects invalid status" do
        subject = described_class.new(platform, campaign, platform_api, valid_attributes.merge(status: "invalid_status"))
        result = subject.action

        expect(result).to eq({
          status: :failed,
          action: :alert,
          message: "Invalid `status` parameter"
        })
      end
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Campaign).to receive(:update!).and_raise(StandardError, "Unexpected error")
      end

      it "rescues error and redirects with alert" do
        result = subject.action

        expect(result).to eq({
          status: :failed,
          action: :alert,
          message: "Failed to update campaign."
        })
      end
    end
  end
end
