# frozen_string_literal: true

require "addressable/uri"
require "faraday"

require_relative "../db/database"
require_relative "models/card"
require_relative "models/card_offer"
require_relative "utils/html_document_parser"

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

    card_offers_params = HtmlDocumentParser.new(response.body).extract_card_offers_params

    DB.transaction do
      # TODO: do not delist previous offers that weren't changed/removed.
      # Delist previous offers.
      card.offers_dataset.current.update(delisted: true, delisted_at: Time.now)
      # Import new offers.
      card_offers_params.each do |params|
        card.add_offer(params)
      end
    end
  end
end
