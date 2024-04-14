# frozen_string_literal: true

require "addressable/uri"

class SingleCardScraper
  SEARCH_URL = "https://mtgtrade.net/store/single/"

  def initialize(card:, connector:, parser:)
    @card = card
    @connector = connector
    @parser = parser
  end

  def run
    card_url = "#{SEARCH_URL}#{URI.encode_www_form_component(@card.name)}"
    html_body = @connector.get(card_url)
    return unless html_body

    card_offers_params = @parser.new(html_body).extract_card_offers_params
    @card.update_offers(card_offers_params)
  end
end
