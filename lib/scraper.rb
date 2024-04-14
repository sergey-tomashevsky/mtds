# frozen_string_literal: true

require "concurrent-ruby"

require_relative "../db/database"
require_relative "models/card"
require_relative "single_card_scraper"

class Scraper
  THREAD_COUNT = 10

  def initialize(connector:, parser:)
    @connector = connector
    @parser = parser
    @total_cards = 0
    @completed_cards = 0
  end

  def run
    query = Card.where(purchased: false).order(:name)
    @total_cards = query.count

    thread_pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: THREAD_COUNT,
      max_threads: THREAD_COUNT,
      max_queue: 0
    )
    query.each do |card|
      thread_pool.post do
        SingleCardScraper.new(card:, connector: @connector, parser: @parser).run
        @completed_cards += 1
        puts "Done looking up prices for #{card.name} [#{progress}]"
      end
    end

    thread_pool.shutdown
    thread_pool.wait_for_termination
    puts "Finished!"
  end

  private

  def progress
    "#{@completed_cards}/#{@total_cards}"
  end
end
