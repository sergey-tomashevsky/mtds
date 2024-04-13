# frozen_string_literal: true

require "sequel"

require_relative "card_offer"

class Card < Sequel::Model
  one_to_many :offers, class: :CardOffer

  def update_offers(offers_params)
    DB.transaction do
      # TODO: do not delist previous offers that weren't changed/removed.
      # Delist previous offers.
      offers_dataset.current.update(delisted: true, delisted_at: Time.now)
      # Import new offers.
      offers_params.each do |params|
        add_offer(params)
      end
    end
  end
end
