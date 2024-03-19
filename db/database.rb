# frozen_string_literal: true

require "sequel"

Sequel.extension :core_extensions
DB = Sequel.connect(
  adapter: :postgres,
  user: "mtgtrade",
  password: "mtgtrade",
  host: "localhost",
  port: 5432,
  database: "mtgtrade",
  max_connections: 5
)
