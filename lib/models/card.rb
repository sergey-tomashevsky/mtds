# frozen_string_literal: true

require "sequel"

require_relative "card_offer"

class Card < Sequel::Model
  one_to_many :offers, class: :CardOffer
end
