#!/usr/bin/env ruby

require "bundler/setup"

require 'terminal-table'
# require 'poppler'
require 'date'
require 'yomu'

def show(file)
  # document = Poppler::Document.new(file)
  # a = document.map { |page| page.get_text }.join

  # reader = PDF::Reader.new(file)
  # reader.pages[0].text

data = File.read file
text = Yomu.read :text, data
require "pry";binding.pry
end


rows = []
Dir["files/*.pdf"] + Dir["files/old/*.txt"].each do |file|
  next unless file.include?("rei")
  filename = file.gsub(/-21-?n?\.pdf/, '-2021').gsub('-22.pdf', '-2022')
  date = Date.parse(filename).strftime("%d.%m.%Y") rescue nil
  next unless date
  # require "pry";binding.pry
  rows << [
    date,
    show(file)
  ]
end

puts Terminal::Table.new :rows => rows

# require "pry";binding.pry
