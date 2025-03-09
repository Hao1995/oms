module CampaignComparable
  def campaigns_attributes_match?(source, target)
    source_attributes = extract_campaign_attributes(source)
    target_attributes = extract_campaign_attributes(target)

    source_attributes == target_attributes
  end

  private

  def extract_campaign_attributes(campaign)
    {
      title: campaign.respond_to?(:title) ? campaign.title : nil,
      currency: campaign.respond_to?(:currency) ? campaign.currency : nil,
      budget_cents: campaign.respond_to?(:budget_cents) ? campaign.budget_cents : nil,
      advertiser_id: campaign.respond_to?(:advertiser_id) ? campaign.advertiser_id : nil
    }
  end
end
