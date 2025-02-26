require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  let(:platform) { create(:platform) }
  let(:advertiser) { create(:advertiser, platform: platform) }
  let(:campaign) { create(:campaign, platform: platform, advertiser: advertiser, status: 'open') }
  let(:valid_attributes) {
    {
      title: "Updated Campaign",
      advertiser_id: advertiser.id,
      budget_cents: 5000,
      currency: "USD",
      status: "open",
      platform_id: platform.id,
      platform_campaign_id: campaign.platform_campaign_id
    }
  }
  let(:invalid_attributes) {
    {
      title: "",
      advertiser_id: nil,
      budget_cents: nil,
      currency: "",
      status: "open"
    }
  }

  before do
    allow(PlatformApi::Factory).to receive(:get_platform).and_return(double(
      "PlatformApi",
      campaign_api: double(
        "CampaignApi",
        get: campaign,
        create: double(id: 123),
        update: true,
        delete: true
      )
    ))
  end

  describe "PUT #update" do
    context "when campaign has no changes" do
      before do
        allow_any_instance_of(CampaignsController).to receive(:are_campaigns_same_content?).and_return(true)
      end

      it "redirects with a notice" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Campaign no changes")
      end
    end

    context "with valid attributes" do
      it "updates the campaign and redirects" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
        campaign.reload
        expect(campaign.title).to eq("Updated Campaign")
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Update the campaign successfully")
      end
    end

    context "with invalid attributes" do
      it "does not update and redirects with alert" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: invalid_attributes }
        expect(response).to redirect_to(edit_platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Failed to update campaign.")
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
    
        campaign_api_double = double("CampaignApi")
        allow(campaign_api_double).to receive(:get).and_return(platform_campaign_stub)
        allow(campaign_api_double).to receive(:create).and_return(double(id: "new-platform-campaign-id"))
        allow(campaign_api_double).to receive(:update).and_return(true)
        allow(campaign_api_double).to receive(:delete).and_return(true)
    
        platform_api_double = double("PlatformApi", campaign_api: campaign_api_double)
    
        allow(PlatformApi::Factory).to receive(:get_platform).and_return(platform_api_double)
        allow_any_instance_of(CampaignsController).to receive(:are_campaigns_same_content?).and_return(false)
        allow_any_instance_of(Campaign).to receive(:updated_at).and_return(1.day.ago)
      end
    
      it "cancels update and redirects with an alert" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
    
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Cancel the update, due to data updates on the platform")
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

        campaign_api_double = double("CampaignApi")
        allow(campaign_api_double).to receive(:get).and_return(platform_campaign_stub)
        allow(campaign_api_double).to receive(:create).and_return(double(id: "new-platform-campaign-id"))
        allow(campaign_api_double).to receive(:delete).and_return(true)

        allow(PlatformApi::Factory).to receive(:get_platform).and_return(double("PlatformApi", campaign_api: campaign_api_double))
      end

      it "updates to open and creates platform campaign" do
        campaign.update!(status: "archive")

        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes.merge(status: "open") }
        campaign.reload
        expect(campaign.status).to eq("open")
        expect(campaign.platform_campaign_id).to eq("new-platform-campaign-id")
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Update campaign successfully")
      end

      it "updates to archive and deletes platform campaign" do
        campaign.update!(status: "open")

        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes.merge(status: "archive") }
        campaign.reload
        expect(campaign.status).to eq("archive")
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Update campaign successfully")
      end

      it "rejects invalid status" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes.merge(status: "invalid_status") }
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Invalid `status` parameter")
      end
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Campaign).to receive(:update!).and_raise(StandardError, "Unexpected error")
      end

      it "rescues error and redirects with alert" do
        put :update, params: { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
        expect(response).to redirect_to(edit_platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Failed to update campaign.")
      end
    end
  end
end
