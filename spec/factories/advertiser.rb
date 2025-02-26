FactoryBot.define do
  factory :advertiser do
    name { "Test Advertiser" }
    customer_id { ENV["CUSTOMER_ID"] || "123" }
    platform
    platform_advertiser_id { SecureRandom.uuid }
  end
end
