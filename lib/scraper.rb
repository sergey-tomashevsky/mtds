# frozen_string_literal: true

require "addressable/uri"
require "faraday"
require "nokogiri"

require_relative "../db/database"
require_relative "models/card"
require_relative "models/card_offer"

class Scraper
  SEARCH_URL = "https://mtgtrade.net/store/single/"
  REQUEST_TIMEOUT = 5

  def initialize
    @connection = Faraday.new { _1.options.timeout = REQUEST_TIMEOUT }
  end

  def run
    query = Card.where(purchased: false)
    total_cards = query.count
    # TODO: add multi-threading for quicker look-up.
    query.each_with_index do |card, index|
      puts "Looking up prices for #{card.name}... (#{index + 1}/#{total_cards})"
      import_card_offers(card)
    end
  end

  private

  def import_card_offers(card)
    begin
      response = @connection.get("#{SEARCH_URL}#{URI.encode_www_form_component(card.name)}")
    rescue Faraday::ConnectionFailed
      puts "Request timeout"
      return
    end

    if response.status != 200
      puts "Error: #{response.status}"
      return
    end

    # TODO: do not delist previous offers that weren't changed/removed.
    # Delist previous offers.
    CardOffer.where(delisted: false, card:).update(delisted: true, delisted_at: Time.now)

    # Import new offers.
    html_doc = Nokogiri::HTML(response.body)
    html_doc.css("div.single-card-sellers table").each do |seller_table|
      seller_name = seller_table.at_css("div.js-crop-text a").content

      seller_table.css("tbody tr").each do |selling_item|
        # Only import offers for cards in Russian language.
        is_russian = !selling_item.at_css(".lang-item-ru").nil?
        next unless is_russian

        # TODO: extract showcase, extended art, retro frame
        set_name =
          selling_item.at_css("img.choose-set").attributes.values.find { _1.name == "alt" }.value
        price = selling_item.at_css("div.catalog-rate-price b").content.split.first.to_i
        foil = !selling_item.at_css("img.foil").nil?

        # TODO: extract params here and wrap new offers create and previous offers update
        # in a single transcation.
        CardOffer.create(card:, price:, foil:, seller_name:, set_name:)
      end
    end
  end
end
