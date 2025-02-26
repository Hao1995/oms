require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  describe "GET #index" do
    let(:customer_id) { ENV["CUSTOMER_ID"] }
    let(:platform) { create(:platform) }
    let(:advertiser) { create(:advertiser, customer_id: customer_id, platform: platform) }
    let!(:campaign1) { create(:campaign, platform_campaign_id: "123", title: "Alpha Campaign", advertiser: advertiser, budget_cents: 5000, currency: "USD", status: "open", platform: platform, customer_id: customer_id, created_at: 2.days.ago, updated_at: 1.day.ago) }
    let!(:campaign2) { create(:campaign, platform_campaign_id: "456", title: "Beta Campaign", advertiser: advertiser, budget_cents: 10000, currency: "EUR", status: "archive", platform: platform, customer_id: customer_id, created_at: 1.day.ago, updated_at: 2.days.ago) }
    let(:platform_api_double) { double("PlatformApi") }

    before do
      allow(PlatformApi::Factory).to receive(:get_platform).and_return(platform_api_double)
    end

    it "returns all campaigns for the given platform" do
      get :index, params: { platform_id: platform.id }
      expect(assigns(:campaigns)).to match_array([ campaign1, campaign2 ])
    end

    it "filters campaigns by title" do
      get :index, params: { platform_id: platform.id, title: "Alpha" }
      expect(assigns(:campaigns)).to eq([ campaign1 ])
    end

    it "filters campaigns by advertiser_id" do
      get :index, params: { platform_id: platform.id, advertiser_id: advertiser.id }
      expect(assigns(:campaigns)).to match_array([ campaign1, campaign2 ])
    end

    it "filters campaigns by budget_cents range" do
      get :index, params: { platform_id: platform.id, budget_cents_min: 6000 }
      expect(assigns(:campaigns)).to eq([ campaign2 ])
    end

    it "filters campaigns by currency" do
      get :index, params: { platform_id: platform.id, currency: "USD" }
      expect(assigns(:campaigns)).to eq([ campaign1 ])
    end

    it "filters campaigns by status" do
      get :index, params: { platform_id: platform.id, status: "archive" }
      expect(assigns(:campaigns)).to eq([ campaign2 ])
    end

    it "filters campaigns by created_at range" do
      get :index, params: { platform_id: platform.id, created_from: 3.days.ago, created_to: Time.zone.now }
      expect(assigns(:campaigns)).to match_array([ campaign1, campaign2 ])
    end

    it "sorts campaigns by created_at descending by default" do
      get :index, params: { platform_id: platform.id }
      expect(assigns(:campaigns)).to eq([ campaign2, campaign1 ])
    end

    it "sorts campaigns by advertiser_name" do
      get :index, params: { platform_id: platform.id, sort_by: "advertiser_name", sort_direction: "asc" }
      expect(assigns(:campaigns)).to match_array([ campaign1, campaign2 ])
    end

    it "paginates results" do
      get :index, params: { platform_id: platform.id, per_page: 1, page: 1 }
      expect(assigns(:campaigns).size).to eq(1)
    end
  end

  describe "PUT #update" do
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
    let(:current_attributes) { valid_attributes }
    let(:req_dto) { Campaigns::UpdateReqDto.new({
      title: current_attributes[:title],
      advertiser_id: current_attributes[:advertiser_id],
      budget_cents: current_attributes[:budget_cents],
      currency: current_attributes[:currency],
      status: current_attributes[:status],
      platform_id: current_attributes[:platform_id],
      platform_campaign_id: current_attributes[:platform_campaign_id]
    }) }

    before do
      allow(PlatformApi::Factory).to receive(:get_platform).and_return(platform_api_double)
    end

    let(:service_response) { Campaigns::UpdateRespDto.new(true, :notice, "Update campaign successfully") }
    let(:service_double) { instance_double(CampaignUpdaterService, action: service_response) }

    before do
      allow(Campaigns::UpdateReqDto).to receive(:new).and_return(req_dto)
      allow(CampaignUpdaterService).to receive(:new).and_return(service_double)
    end

    context "when update is successful" do
      it "calls the service and redirects with notice" do
        params = { platform_id: platform.id, id: campaign.id, campaign: valid_attributes }
        put :update, params: params, as: :json

        expect(CampaignUpdaterService).to have_received(:new).with(platform, campaign, platform_api_double, req_dto)
        expect(service_double).to have_received(:action)
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq("Update campaign successfully")
      end
    end

    context "when update fails" do
      let(:service_response) { Campaigns::UpdateRespDto.new(false, :alert, "Failed to update campaign.") }
      let(:current_attributes) { invalid_attributes }

      it "redirects with alert" do
        params = { platform_id: platform.id, id: campaign.id, campaign: invalid_attributes }
        put :update, params: params, as: :json

        expect(CampaignUpdaterService).to have_received(:new).with(platform, campaign, platform_api_double, req_dto)
        expect(response).to redirect_to(edit_platform_campaign_path(platform, campaign))
        expect(flash[:alert]).to eq("Failed to update campaign.")
      end
    end
  end

  describe 'POST #create' do
    let(:platform) { create(:platform) }
    let(:advertiser) { create(:advertiser, platform_advertiser_id: '1234') }
    let(:valid_attributes) do
      {
        title: 'Test Campaign',
        advertiser_id: advertiser.id,
        currency: 'USD',
        budget_cents: 500000 # Represents $5000
      }
    end

    let(:invalid_attributes) do
      {
        title: nil, # Required
        advertiser_id: advertiser.id,
        currency: nil, # Required
        budget_cents: nil # Required
      }
    end

    let(:campaign_api) { double("CampaignApi") }
    let(:platform_api_double) { double("PlatformApi", campaign_api: campaign_api) }

    before do
      allow(Advertiser).to receive(:find_by).with(advertiser.id.to_s).and_return(advertiser)
      allow(campaign_api).to receive(:create).and_return(double(id: "5678"))
      allow(PlatformApi::Factory).to receive(:get_platform).and_return(platform_api_double)
    end

    context 'when the campaign is successfully created' do
      it 'creates a new campaign and redirects to the campaign show page' do
        expect {
          post :create, params: { campaign: valid_attributes, platform_id: platform.id }
        }.to change(Campaign, :count).by(1)

        campaign = Campaign.last
        expect(response).to redirect_to(platform_campaign_path(platform, campaign))
        expect(flash[:notice]).to eq('Campaign was successfully created.')
      end
    end

    context 'when the campaign creation fails' do
      it 'does not create a campaign and redirects with an alert' do
        expect {
          post :create, params: { campaign: invalid_attributes, platform_id: platform.id }
        }.not_to change(Campaign, :count)

        expect(response).to redirect_to(platform_campaigns_path(platform))
        expect(flash[:alert]).to eq('Failed to create campaign.')
      end
    end
  end
end
