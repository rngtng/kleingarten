#!/usr/bin/env ruby

require "bundler/setup"

require 'terminal-table'
require 'date'

def show(file)
  data = File.read file
  data.split("preis").size
end

rows = []
Dir["files/old/*.txt"].each do |file|
  date = Date.parse(file) rescue nil
  rows << [
    date,
    show(file)
  ]
end

puts Terminal::Table.new :rows => rows.sort_by! { |r| r[0] }

# require "pry";binding.pry
