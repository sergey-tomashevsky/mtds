require "nokogiri"

class HtmlDocumentParser
  def initialize(document)
    @html_doc = Nokogiri::HTML(document)
  end

  def extract_card_offers_params(russian_only: true)
    @html_doc.css("div.single-card-sellers table").reduce([]) do |all_offer_params, seller_table|
      seller_name = seller_table.at_css("div.js-crop-text a").content

      offer_params_by_seller =
        seller_table.css("tbody tr").reduce([]) do |offer_params, selling_item|
          if russian_only
            is_russian = !selling_item.at_css(".lang-item-ru").nil?
            next offer_params unless is_russian
          end

          # TODO: extract showcase, extended art, retro frame
          set_name =
            selling_item.at_css("img.choose-set").attributes.values.find { _1.name == "alt" }.value
          price = selling_item.at_css("div.catalog-rate-price b").content.split.first.to_i
          foil = !selling_item.at_css("img.foil").nil?

          offer_params << { price:, foil:, seller_name:, set_name: }
        end

      all_offer_params + offer_params_by_seller
    end
  end
end
