class Platform < ApplicationRecord
  has_many :campaigns

  validates :name, presence: true
end
