require "rails_helper"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.describe PlatformApi::Campaign::Megaphone do
  let(:platform_name) { "megaphone" }
  let(:service) { described_class.new(platform_name) }
  let(:campaign_id) { "test-campaign-123" }
  let(:headers) do
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['MEGAPHONE_TOKEN']}"
    }
  end

  let(:campaign_data) do
    {
      title: "Test Campaign",
      advertiser_id: "adv-123",
      budget_cents: 10000,
      currency: "USD"
    }
  end

  let(:campaign_response) do
    {
      "id" => campaign_id,
      "title" => campaign_data[:title],
      "advertiserId" => campaign_data[:advertiser_id],
      "totalBudgetCents" => campaign_data[:budget_cents],
      "totalBudgetCurrency" => campaign_data[:currency],
      "createdAt" => "2024-03-20T00:00:00Z",
      "updatedAt" => "2024-03-20T00:00:00Z"
    }
  end

  describe "#get" do
    it "fetches a campaign successfully" do
      stub_request(:get, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(headers: headers)
        .to_return(status: 200, body: campaign_response.to_json)

      response = service.get(campaign_id)

      expect(response).to be_a(ThirdParty::Campaigns::ResponseDto)
      expect(response.id).to eq(campaign_id)
      expect(response.title).to eq(campaign_data[:title])
      expect(response.advertiser_id).to eq(campaign_data[:advertiser_id])
      expect(response.budget_cents).to eq(campaign_data[:budget_cents])
      expect(response.currency).to eq(campaign_data[:currency])
    end

    it "raise NotFoundException when campaign is not found" do
      stub_request(:get, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(headers: headers)
        .to_return(status: 404)

      expect { service.get(campaign_id) }.to raise_error(Http::NotFoundException)
    end
  end

  describe "#list" do
    let(:pagination_headers) do
      {
        "x-total" => "100",
        "x-per-page" => "10",
        "x-page" => "1"
      }
    end

    it "lists campaigns with pagination" do
      stub_request(:get, "#{described_class::BASE_URL}?page=1&per_page=100")
        .with(headers: headers)
        .to_return(
          status: 200,
          body: [ campaign_response ].to_json,
          headers: pagination_headers
        )

      response = service.list

      expect(response.campaigns).to be_an(Array)
      expect(response.pagination.total).to eq(100)
      expect(response.pagination.per_page).to eq(10)
      expect(response.pagination.current_page).to eq(1)
    end
  end

  describe "#create" do
    let(:request_body) do
      {
        title: campaign_data[:title],
        advertiserId: campaign_data[:advertiser_id],
        totalBudgetCents: campaign_data[:budget_cents],
        totalBudgetCurrency: campaign_data[:currency]
      }
    end

    it "creates a campaign successfully" do
      stub_request(:post, described_class::BASE_URL)
        .with(
          headers: headers,
          body: request_body.to_json
        )
        .to_return(status: 201, body: campaign_response.to_json)

      response = service.create(campaign_data)

      expect(response).to be_a(ThirdParty::Campaigns::ResponseDto)
      expect(response.id).to eq(campaign_id)
      expect(response.title).to eq(campaign_data[:title])
    end

    it "raises error when creation too many requests" do
      stub_request(:post, described_class::BASE_URL)
        .with(
          headers: headers,
          body: request_body.to_json
        )
        .to_return(status: 429, body: { error: "Invalid data" }.to_json)

      expect { service.create(campaign_data) }.to raise_error(Http::TooManyRequestsException)
    end
  end

  describe "#update" do
    let(:request_body) do
      {
        title: campaign_data[:title],
        advertiserId: campaign_data[:advertiser_id],
        totalBudgetCents: campaign_data[:budget_cents],
        totalBudgetCurrency: campaign_data[:currency]
      }
    end

    it "updates a campaign successfully" do
      stub_request(:put, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(
          headers: headers,
          body: request_body.to_json
        )
        .to_return(status: 200, body: campaign_response.to_json)

      response = service.update(campaign_id, campaign_data)

      expect(response).to be_a(ThirdParty::Campaigns::ResponseDto)
      expect(response.id).to eq(campaign_id)
      expect(response.title).to eq(campaign_data[:title])
    end

    it "raises error when update too many requests" do
      stub_request(:put, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(
          headers: headers,
          body: request_body.to_json
        )
        .to_return(status: 429, body: { error: "Invalid data" }.to_json)

      expect { service.update(campaign_id, campaign_data) }.to raise_error(Http::TooManyRequestsException)
    end
  end

  describe "#delete" do
    it "deletes a campaign successfully" do
      stub_request(:delete, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(headers: headers)
        .to_return(status: 204)

      expect(service.delete(campaign_id)).to be true
    end

    it "raises error when campaign not found" do
      stub_request(:delete, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(headers: headers)
        .to_return(status: 404)

      expect { service.delete(campaign_id) }.to raise_error(Http::NotFoundException)
    end
  end

  describe "rate limiting" do
    it "raises TooManyRequestsException when rate limited" do
      stub_request(:get, "#{described_class::BASE_URL}/#{campaign_id}")
        .with(headers: headers)
        .to_return(status: 429, body: { error: "Rate limited" }.to_json)

      expect { service.get(campaign_id) }.to raise_error(Http::TooManyRequestsException)
    end
  end
end
