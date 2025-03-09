require 'rails_helper'

RSpec.describe AdvertiserSyncWorker, type: :worker do
  let(:platform) { create(:platform, name: 'megaphone') }
  let(:advertiser_api) { instance_double(PlatformApi::Advertiser::Megaphone) }
  let(:platform_api) { instance_double(PlatformApi::MegaphonePlatformApi, advertiser_api: advertiser_api) }
  let(:platform_api_factory) { class_double(PlatformApi::Factory).as_stubbed_const }
  let(:page) { 1 }
  let(:per_page) { 100 }

  let(:advertiser_data) do
    [
      {
        "id" => "adv-1",
        "name" => "Advertiser 1",
        "agencyId" => "agency-1",
        "competitiveCategories" => "category-1",
        "createdAt" => Time.current,
        "updatedAt" => Time.current
      },
      {
        "id" => "adv-2",
        "name" => "Advertiser 2",
        "agencyId" => "agency-2",
        "competitiveCategories" => "category-2",
        "createdAt" => Time.current,
        "updatedAt" => Time.current
      }
    ]
  end

  let(:pagination) do
    Common::PaginationDto.new(
      total: 2,
      per_page: per_page,
      current_page: page
    )
  end

  before do
    platform # init first
    allow(Rails.application.config).to receive(:platforms).and_return({ 'megaphone' => {} })
    allow(platform_api_factory).to receive(:get_platform).with('megaphone').and_return(platform_api)
  end

  describe '#perform' do
    context 'when fetching advertisers from platform' do
      before do
        allow(advertiser_api).to receive(:list).and_return(
          ThirdParty::Advertisers::ListResponseDto.from_response(
            advertisers: advertiser_data,
            pagination: pagination
          )
        )
      end

      it 'creates new advertisers in the database' do
        expect(Advertiser.count).to eq(0)

        expect {
          subject.perform(page: page, per_page: per_page)
        }.to change(Advertiser, :count).by(2)

        expect(Advertiser.pluck(:platform_advertiser_id)).to match_array([ 'adv-1', 'adv-2' ])
        expect(Advertiser.pluck(:name)).to match_array([ 'Advertiser 1', 'Advertiser 2' ])
      end

      it 'updates existing advertisers' do
        existing_advertiser = create(:advertiser,
          platform: platform,
          platform_advertiser_id: 'adv-1',
          name: 'Old Name'
        )

        expect {
          subject.perform(page: page, per_page: per_page)
        }.to change(Advertiser, :count).by(1)

        existing_advertiser.reload
        expect(existing_advertiser.name).to eq('Advertiser 1')
      end

      it 'handles multiple pages' do
        first_page = ThirdParty::Advertisers::ListResponseDto.from_response(
          advertisers: [ advertiser_data.first ],
          pagination: Common::PaginationDto.new(total: 2, per_page: 1, current_page: 1)
        )

        second_page = ThirdParty::Advertisers::ListResponseDto.from_response(
          advertisers: [ advertiser_data.last ],
          pagination: Common::PaginationDto.new(total: 2, per_page: 1, current_page: 2)
        )

        allow(advertiser_api).to receive(:list).with(hash_including(page: 1)).and_return(first_page)
        allow(advertiser_api).to receive(:list).with(hash_including(page: 2)).and_return(second_page)

        expect {
          subject.perform(page: 1, per_page: 1)
        }.to change(Advertiser, :count).by(2)

        expect(advertiser_api).to have_received(:list).twice
      end
    end

    context 'when API returns empty results' do
      before do
        allow(advertiser_api).to receive(:list).and_return(
          ThirdParty::Advertisers::ListResponseDto.from_response(
            advertisers: [],
            pagination: Common::PaginationDto.new(total: 0, per_page: per_page, current_page: page)
          )
        )
      end

      it 'does not create any advertisers' do
        expect {
          subject.perform(page: page, per_page: per_page)
        }.not_to change(Advertiser, :count)
      end
    end
  end
end
