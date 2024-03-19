# frozen_string_literal: true

require_relative "database"

class Migration
  class << self
    def run
      add_cards
      add_card_offers
    end

    private

    def add_cards
      return if DB.table_exists?(:cards)

      DB.create_table :cards do
        primary_key :id
        String :name
        TrueClass :purchased, default: false
        index :name, unique: true
      end
    end

    def add_card_offers
      return if DB.table_exists?(:card_offers)

      DB.create_table :card_offers do
        primary_key :id
        Integer :price, null: false
        TrueClass :foil, nil: false, default: false
        String :seller_name, nil: false
        String :set_name, nil: false
        TrueClass :delisted, nil: false, default: false
        DateTime :delisted_at
        foreign_key :card_id, :cards, null: false, index: true
        index :seller_name
      end
    end
  end
end
