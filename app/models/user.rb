class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email_address, presence: true, uniqueness: true
  validates :terms_accepted_at, presence: true
end
