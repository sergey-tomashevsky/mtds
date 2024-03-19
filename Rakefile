# frozen_string_literal: true

require "rubocop/rake_task"

task default: %w[lint test]

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = ["lib/**/*.rb", "test/**/*.rb"]
  task.fail_on_error = false
end

task :scrape_offers do
  require_relative "lib/scraper"
  Scraper.new.run
end

task :show_offers do
  require "optparse"
  require_relative "lib/analyzer"

  options = {}
  opts = OptionParser.new
  opts.banner = "Usage: rake show_offers [options]"
  opts.on("--maxprice VALUE", Integer, "Maximum price per card.") { |mp| options[:max_price] = mp }
  opts.on("--foil", TrueClass, "Include foil cards.") { |f| options[:include_foils] = !f.nil? }
  args = opts.order!(ARGV) { |_| } # Block content isn't important here.
  opts.parse!(args)

  Analyzer.run(**options)
  exit
end

task :db_drop do
  system "dropdb mtgtrade"
  puts "DB dropped"
end

task :db_create do
  system "createdb mtgtrade"
  puts "DB created"
end

task :db_migrate do
  require_relative "db/migration"

  Migration.run
end

task :db_seed do
  ruby "db/seed.rb"
  puts "DB seeded"
end

task :db_reset do
  %w[db_drop db_create db_migrate db_seed].each { Rake::Task[_1].invoke }
end

task :test do
  ruby "test/script_test.rb"
end
