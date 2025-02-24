class AdvertiserResponseDto
  attr_accessor :id, :name

  def initialize(id:, name:, created_at:, updated_at:)
    @id = id
    @name = name
    @created_at = created_at
    @updated_at = updated_at
  end
  
  def to_json
    {
      id: @id,
      name: @name,
      created_at: @created_at,
      updated_at: @updated_at
    }.to_json
  end
end