require 'rails_helper'

RSpec.describe CampaignSyncWorker, type: :worker do
  let(:platform) { create(:platform, name: 'megaphone') }
  let(:advertiser) { create(:advertiser, platform: platform, platform_advertiser_id: 'adv') }

  let(:campaign_api) { instance_double(PlatformApi::Campaign::Megaphone) }
  let(:platform_api) { instance_double(PlatformApi::MegaphonePlatformApi, campaign_api: campaign_api) }
  let(:platform_api_factory) { class_double(PlatformApi::Factory).as_stubbed_const }

  let(:campaign_data) do
    [
      {
        "id" => "camp-1",
        "title" => "Campaign 1",
        "advertiserId" => "adv",
        "totalBudgetCents" => "10000",
        "totalBudgetCurrency" => "USD"
      },
      {
        "id" => "camp-2",
        "title" => "Campaign 2",
        "advertiserId" => "adv",
        "totalBudgetCents" => "20000",
        "totalBudgetCurrency" => "USD"
      }
    ]
  end

  let(:pagination) do
    PaginationDto.new(
      total: 2,
      per_page: 100,
      current_page: 1
    )
  end

  before do
    # init first
    platform
    advertiser

    allow(Rails.application.config).to receive(:platforms).and_return({ 'megaphone' => {} })
    allow(platform_api_factory).to receive(:get_platform).with('megaphone').and_return(platform_api)
  end

  describe '#perform' do
    context 'when fetching campaigns from platform' do
      before do
        allow(campaign_api).to receive(:list).and_return(
          CampaignListResponseDto.from_response(
            campaigns: campaign_data,
            pagination: pagination
          )
        )
      end

      it 'creates new campaigns in the database' do
        expect(Campaign.count).to eq(0)

        expect {
          subject.perform
        }.to change(Campaign, :count).by(2)

        expect(Campaign.pluck(:platform_campaign_id)).to match_array([ 'camp-1', 'camp-2' ])
        expect(Campaign.pluck(:title)).to match_array([ 'Campaign 1', 'Campaign 2' ])
      end

      it 'updates existing campaigns when data changes' do
        existing_campaign = create(:campaign,
          customer_id: ENV['CUSTOMER_ID'],
          platform: platform,
          platform_campaign_id: 'camp-1',
          title: 'Old Title',
          currency: 'USD',
          budget_cents: 5000,
          advertiser_id: advertiser.id
        )

        expect {
          subject.perform
        }.to change(Campaign, :count).by(1)

        existing_campaign.reload
        expect(existing_campaign.title).to eq('Campaign 1')
        expect(existing_campaign.budget_cents).to eq(10000)
      end

      it 'does not update campaigns when data remains the same' do
        existing_campaign = create(:campaign,
          customer_id: ENV['CUSTOMER_ID'],
          platform: platform,
          platform_campaign_id: 'camp-1',
          title: 'Campaign 1',
          currency: 'USD',
          budget_cents: 10000,
          advertiser_id: advertiser.id
        )

        expect {
          subject.perform
        }.to change(Campaign, :count).by(1)

        expect(existing_campaign.reload.updated_at.to_i).to eq(existing_campaign.updated_at.to_i)
      end

      it 'handles multiple pages' do
        first_page = CampaignListResponseDto.from_response(
          campaigns: [ campaign_data.first ],
          pagination: PaginationDto.new(total: 2, per_page: 1, current_page: 1)
        )

        second_page = CampaignListResponseDto.from_response(
          campaigns: [ campaign_data.last ],
          pagination: PaginationDto.new(total: 2, per_page: 1, current_page: 2)
        )

        allow(campaign_api).to receive(:list)
          .with(hash_including(page: 1, per_page: 1))
          .and_return(first_page)
        allow(campaign_api).to receive(:list)
          .with(hash_including(page: 2, per_page: 1))
          .and_return(second_page)

        expect {
          subject.perform(page: 1, per_page: 1)
        }.to change(Campaign, :count).by(2)

        expect(campaign_api).to have_received(:list).twice
      end
    end

    context 'when API returns empty results' do
      before do
        allow(campaign_api).to receive(:list).and_return(
          CampaignListResponseDto.from_response(
            campaigns: [],
            pagination: PaginationDto.new(total: 0, per_page: 100, current_page: 1)
          )
        )
      end

      it 'does not create any campaigns' do
        expect {
          subject.perform
        }.not_to change(Campaign, :count)
      end
    end
  end
end
