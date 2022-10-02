#!/usr/bin/env ruby

require "bundler/setup"

require 'terminal-table'
require 'date'

def show(file)
  data = File.read(file)
  data = data.split("www.bdk-schoeneberg.de").last.strip.split("\n")
  data.select! { |line| line.include?("€") || line.include?("Kol") }
  data = combine(data).sort
  data = split(data)
  data.join("\n")
end

def split(data)
  data.each do |l|
    require "pry";binding.pry
    l.scan(/[a-züäö .]+/i)
  end
end

def combine(data)
  # require "pry";binding.pry
  half = data.size / 2
  combined = data[0...half].map.with_index do |line, index|
    line + data[half + index]
  end
  # require "pry";binding.pry if data.include?("Kol. Frohsinn 46")
  return data if combined.first.nil? || combined.first.count("€") > 1 || combined.first.split("Kol").size > 2
  combined
end

rows = []
Dir["files/old/*.txt"].each do |file|
  date = Date.parse(file) rescue nil
  rows << [
    date,
    file,
    show(file)
  ]
end

puts Terminal::Table.new :rows => rows.sort_by! { |r| r[0] }

# require "pry";binding.pry
