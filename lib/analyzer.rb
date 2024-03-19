# frozen_string_literal: true

require "colorize"

require_relative "../db/database"
require_relative "models/card"
require_relative "models/card_offer"

class Analyzer
  class << self
    def run(max_price: nil, include_foils: false)
      best_offers_by_seller = {}

      offers_query =
        CardOffer
        .association_join(:card)
        .current
        .where(card: Card.where(purchased: false))
        .select_all(:card_offers)
        .select_append(Sequel.function(:min, :price).over(partition: :card_id).as(:best_price))

      offers_query = offers_query.filter { price <= max_price } if max_price
      offers_query = offers_query.where(foil: false) unless include_foils

      offers_query.each do |offer|
        best_offers_by_seller[offer.seller_name] ||= []
        best_offers_by_seller[offer.seller_name] << offer
      end

      sorted_best_offers_by_seller = best_offers_by_seller.sort_by { |_, offers| offers.size }
      sorted_best_offers_by_seller.reverse.to_h.each do |seller_name, offers|
        puts "Seller: #{seller_name}"
        puts "Total sum: #{offers.sum(&:price)} rub, amount of cards: #{offers.size}"

        offers.sort_by(&:price).reverse.each do |offer|
          best_card_price = offer.values[:best_price]

          price_color = offer.price == best_card_price ? :light_green : :light_yellow
          additional_info = ["#{offer.price} rub".colorize(price_color)]

          if offer.price > best_card_price
            additional_info << "lowest: #{"#{best_card_price} rub".colorize(:light_green)}"
          end
          additional_info << "PROMO" if offer.set_name.downcase.start_with?("promo")
          additional_info << "FOIL" if offer.foil
          puts "- #{offer.card.name} (#{additional_info.join(', ')})"
        end
        puts "============================================"
      end
    end
  end
end
