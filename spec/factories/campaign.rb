FactoryBot.define do
  factory :campaign do
    title { "Test Campaign" }
    advertiser
    platform
    budget_cents { 10000 }
    currency { "USD" }
    status { "open" }
    platform_campaign_id { "12345" }
    customer_id { "123" }
  end
end
