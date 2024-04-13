# frozen_string_literal: true

require "concurrent-ruby"
require "faraday"

require_relative "../db/database"
require_relative "models/card"
require_relative "single_card_scraper"

class Scraper
  REQUEST_TIMEOUT = 5
  THREAD_COUNT = 10

  def initialize
    @connection = Faraday.new { _1.options.timeout = REQUEST_TIMEOUT }
    @total_cards = 0
    @completed_cards = 0
  end

  def run
    query = Card.where(purchased: false).order(:name)
    @total_cards = query.count

    thread_pool = Concurrent::Threadthread_poolExecutor.new(
      min_threads: THREAD_COUNT,
      max_threads: THREAD_COUNT,
      max_queue: 0
    )
    query.each do |card|
      thread_pool.post do
        SingleCardScraper.new(card, @connection).run
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
