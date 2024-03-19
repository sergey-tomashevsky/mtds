# frozen_string_literal: true

require "sequel"

require_relative "card"

class CardOffer < Sequel::Model
  many_to_one :card, class: :Card

  dataset_module do
    def current
      where(delisted: false)
    end
  end
end
