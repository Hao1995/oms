require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  let(:platform) { create(:platform) }
  let(:advertiser) { create(:advertiser, platform: platform) }
  let(:campaign) { create(:campaign, platform: platform, advertiser: advertiser, status: 'open') }
  let(:platform_api_double) { double("PlatformApi") }
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
    allow(PlatformApi::Factory).to receive(:get_platform).and_return(platform_api_double)
  end

  describe "PUT #update" do
    let(:service_response) { { status: :success, action: :notice, message: "Update campaign successfully" } }
    let(:service_double) { instance_double(CampaignUpdaterService, action: service_response) }

    before do
      allow(CampaignUpdaterService).to receive(:new).and_return(service_double)
    end

    context "when update is successful" do
      it "calls the service and redirects with notice" do
        params = { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
        put :update, params: params, as: :json

        received_params = ActionController::Parameters.new(params)
                                                      .require(:campaign)
                                                      .permit(
                                                        :platform_id, 
                                                        :platform_campaign_id, 
                                                        :title, 
                                                        :currency, 
                                                        :budget_cents, 
                                                        :advertiser_id,
                                                        :status
                                                      ).merge(customer_id: ENV["CUSTOMER_ID"])
        expect(CampaignUpdaterService).to have_received(:new).with(platform, campaign, platform_api_double, received_params)
        expect(service_double).to have_received(:action)
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Update campaign successfully")
      end
    end

    context "when update fails" do
      let(:service_response) { { status: :failed, action: :alert, message: "Failed to update campaign." } }

      it "redirects with alert" do
        params = { platform_id: platform.id, id: campaign.id, campaign: invalid_attributes }
        put :update, params: params, as: :json

        received_params = ActionController::Parameters.new(params)
                                                      .require(:campaign)
                                                      .permit(
                                                        :platform_id, 
                                                        :platform_campaign_id, 
                                                        :title, 
                                                        :currency, 
                                                        :budget_cents, 
                                                        :advertiser_id,
                                                        :status
                                                      ).merge(customer_id: ENV["CUSTOMER_ID"])
        expect(CampaignUpdaterService).to have_received(:new).with(platform, campaign, platform_api_double, received_params)
        expect(response).to redirect_to(edit_platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Failed to update campaign.")
      end
    end
  end
end
