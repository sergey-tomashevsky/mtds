# frozen_string_literal: true

require "colorize"

require_relative "../db/database"
require_relative "models/card"
require_relative "models/card_offer"

class Analyzer
  def initialize(max_price: nil, include_foils: false, min_offers: 1)
    @max_price = max_price
    @include_foils = include_foils
    @min_offers = min_offers
  end

  def run
    sorted_offers = collect_offers_grouped_by_seller
    sorted_offers.each_with_index do |offers, index|
      print_seller_offers(*offers)
      print_separator if index < sorted_offers.keys.length - 1
    end
  end

  private

  def collect_offers_grouped_by_seller
    offers_query =
      CardOffer
      .association_join(:card)
      .current
      .where(card: Card.where(purchased: false))
      .select_all(:card_offers)
      .select_append(Sequel.function(:min, :price).over(partition: :card_id).as(:best_price))

    offers_query = offers_query.filter { price <= @max_price } if @max_price
    offers_query = offers_query.where(foil: false) unless @include_foils

    best_offers_by_seller =
      offers_query.each_with_object({}) do |offer, collection|
        collection[offer.seller_name] ||= []
        collection[offer.seller_name] << offer
      end

    best_offers_by_seller
      .filter { |_, offers| offers.length >= @min_offers }
      .sort_by { |_, offers| offers.length }
      .reverse
      .to_h
  end

  def print_seller_offers(seller_name, offers)
    puts "Seller: #{seller_name}"
    puts "Total sum: #{offers.sum(&:price)} rub, amount of cards: #{offers.length}"

    offers
      .sort_by(&:price)
      .reverse
      .each { print_offer(_1) }
  end

  def print_offer(offer)
    best_card_price = offer.values[:best_price]

    price_color = offer.price == best_card_price ? :light_green : :light_yellow
    additional_info = ["#{offer.price} rub".colorize(price_color)]

    if offer.price > best_card_price
      additional_info << "cheapest: #{"#{best_card_price} rub".colorize(:light_green)}"
    end
    additional_info << "PROMO" if offer.set_name.downcase.start_with?("promo")
    additional_info << "FOIL" if offer.foil
    puts "- #{offer.card.name} (#{additional_info.join(', ')})"
  end

  def print_separator
    puts "============================================"
  end
end
