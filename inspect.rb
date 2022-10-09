#!/usr/bin/env ruby

require "bundler/setup"

require 'terminal-table'
require 'date'
require 'json'

class Entry
  attr_reader :files, :name

  def initialize(name, nr, prize, file)
    @name = norm(name)
    @nr = nr
    @prize = prize
    @files = [file]
  end

  def dates
    @files.map { |f| Date.parse(f) }
  end

  def to_s
    [@name, @nr].join
  end

  private

  def norm(name)
    name.scan(/(Kolo?(nie)?\.?)?([a-züöä -]+)/i)
      .first[2]
      .gsub(/ P(arz)?/, "")
      .gsub("Kleingartenanlage", "")
      .gsub(" - ", "-")
      .gsub("-", " ")
      .gsub("Ziegenweidde", "Ziegenweide")
      .gsub("Alt Z", "Alte Z")
      .gsub("Schoeneberg", "Schöneberg")
      .gsub("Kaninchenfarm e", "Kaninchenfarm")
      .strip
  end
end

def lines(file)
  data = File.read(file)
  data = data.split("www.bdk-schoeneberg.de").last.strip.split("\n")
  data.select! { |line| line.include?("€") || line.include?("Kol") }
  combine(data)
end

def combine(data)
  half = data.size / 2
  combined = data[0...half].map.with_index do |line, index|
    line + data[half + index]
  end
  return data if combined.first.nil? || combined.first.count("€") > 1 || combined.first.split("Kol").size > 2
  combined
end

@entries = {}
Dir["files/old/*.txt"].each do |file|
  # `cp #{file.gsub(".txt", ".pdf")} files/norm/#{Date.parse(file)}.pdf`
  lines(file).map do |line|
    name, nr, prize = *line.scan(/([^\d]+)(\d+)[^\d]+([\d.]+)/i).first
    entry = Entry.new(name, nr, prize.delete("."), file)
    if @entries[entry.to_s]
      @entries[entry.to_s].files << entry.files.first
    else
      @entries[entry.to_s] = entry
    end
  end
end

@kols = @entries.values.map(&:name).uniq.sort
@dates = @entries.values.map(&:dates).flatten.uniq.sort

a = @entries.sort_by { |k,v| v.dates.sort.first }


@rows = []
@rows << ["Kol"] + @dates
Hash[a].each do |key, entry|
  @rows << [entry.to_s] + @dates.map do |date|
    entry.dates.include?(date) ? 1 : 0
  end
end


# @dates.uniq.sort.each do |date|
#   k = @kols.each_with_object({}) { |name, hash| hash[name] = 0 }
#   @entries.each do |key, entry|
#     k[entry.name] += 1 if entry.dates.include?(date)
#   end

# end

# @rows.transpose.each do |row|
#   puts row.join("\t")
# end
# puts Terminal::Table.new :rows => @rows

series = @entries.values.map do |e|
  { name: e.to_s, data: @dates.map { |d| [d.to_time.to_i * 1000, e.dates.include?(d) ? 1 : 0]}  }
end


puts <<~HTML
<html>
  <script src="https://code.highcharts.com/highcharts.js"></script>
  <body>
    <div id="container" style="width:100%; height:400px;"></div>
    <script>
      document.addEventListener('DOMContentLoaded', function () {
        const chart = Highcharts.chart('container', {
            chart: {
              type: 'area',
              zoomType: 'x'
          },
            xAxis: {
              type: 'datetime'
            },
            plotOptions: {
              area: {
                  stacking: 'normal',
              }
            },
            series: #{series.to_json}
        });
      });
    </script>
  </body>
</html>
HTML
