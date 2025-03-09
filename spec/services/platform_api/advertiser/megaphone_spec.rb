require "rails_helper"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.describe PlatformApi::Advertiser::Megaphone do
  let(:platform_name) { "megaphone" }
  let(:service) { described_class.new(platform_name) }
  let(:headers) do
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['MEGAPHONE_TOKEN']}"
    }
  end

  let(:advertiser_data) do
    {
      "id" => "0072594c-1278-11ed-9327-bb84a5f93a77",
      "agencyId" => nil,
      "name" => "NIKE2",
      "createdAt" => "2022-08-02T15:30:13.120Z",
      "updatedAt" => "2023-03-23T18:44:59.643Z",
      "competitiveCategories" => "ADV-6-44,ADV-6-43"
    }
  end

  describe "#list" do
    let(:pagination_headers) do
      {
        "x-total" => "100",
        "x-per-page" => "10",
        "x-page" => "1"
      }
    end

    it "lists advertisers with pagination" do
      stub_request(:get, "#{described_class::BASE_URL}?page=1&per_page=100")
        .with(headers: headers)
        .to_return(
          status: 200,
          body: [ advertiser_data ].to_json,
          headers: pagination_headers
        )

      response = service.list
      puts "test. response: #{response.to_json}"

      expect(response.advertisers).to be_an(Array)
      expect(response.advertisers.first).to have_attributes(
        id: advertiser_data["id"],
        name: advertiser_data["name"],
        agency_id: advertiser_data["agencyId"],
        competitive_categories: advertiser_data["competitiveCategories"],
        created_at: Time.parse(advertiser_data["createdAt"]),
        updated_at: Time.parse(advertiser_data["updatedAt"])
      )
      expect(response.pagination.total).to eq(100)
      expect(response.pagination.per_page).to eq(10)
      expect(response.pagination.current_page).to eq(1)
    end

    it "lists advertisers with custom pagination parameters" do
      stub_request(:get, "#{described_class::BASE_URL}?page=2&per_page=50")
        .with(headers: headers)
        .to_return(
          status: 200,
          body: [ advertiser_data ].to_json,
          headers: {
            "x-total" => "150",
            "x-per-page" => "50",
            "x-page" => "2"
          }
        )

      response = service.list(page: 2, per_page: 50)

      expect(response.advertisers).to be_an(Array)
      expect(response.pagination.total).to eq(150)
      expect(response.pagination.per_page).to eq(50)
      expect(response.pagination.current_page).to eq(2)
    end
  end

  describe "error handling" do
    it "raises TooManyRequestsException when rate limited" do
      stub_request(:get, "#{described_class::BASE_URL}?page=1&per_page=100")
        .with(headers: headers)
        .to_return(status: 429, body: { error: "Rate limited" }.to_json)

      expect { service.list }.to raise_error(Http::TooManyRequestsException)
    end

    it "raises BaseException for other errors" do
      stub_request(:get, "#{described_class::BASE_URL}?page=1&per_page=100")
        .with(headers: headers)
        .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)

      expect { service.list }.to raise_error(Http::BaseException)
    end
  end
end
