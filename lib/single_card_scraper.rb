# frozen_string_literal: true

require "addressable/uri"
require_relative "utils/html_document_parser"

class SingleCardScraper
  SEARCH_URL = "https://mtgtrade.net/store/single/"

  def initialize(card, connection)
    @card = card
    @connection = connection
  end

  def run
    html_body = request_store_page
    return unless html_body

    card_offers_params = HtmlDocumentParser.new(html_body).extract_card_offers_params
    @card.update_offers(card_offers_params)
  end

  private

  def request_store_page
    begin
      response = @connection.get("#{SEARCH_URL}#{URI.encode_www_form_component(@card.name)}")
    rescue Faraday::ConnectionFailed
      puts "Request timeout"
      return nil
    end

    if response.status != 200
      puts "Error: #{response.status}"
      return nil
    end

    response.body
  end
end
