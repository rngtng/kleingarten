#!/usr/bin/env ruby

require "bundler/setup"

require "terminal-table"
require "date"
require "json"

# https://bdk-schoeneberg.de/uebersicht/

class Entry
  attr_reader :files, :name
  attr_accessor :all_dates

  def initialize(name, nr, prize, file)
    @name = norm(name)
    @nr = nr
    @prize = prize
    @files = [file]
  end

  def dates
    @dates ||= @files.map { |f| Date.parse(f) }.sort
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
      .tr("-", " ")
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
  combine(lines(file)).map do |line|
    entry = begin
      line.gsub!("bitte erfragen", "0")
      line.gsub!("ca.", "0")
      name, nr, prize = *line.scan(/([^\d]+)(\d+)[^\d]+([\d.]+)/i).first
      Entry.new(name, nr, prize.delete("."), file)
    rescue
      require "pry";binding.pry
    end
    if @entries[entry.to_s]
      @entries[entry.to_s].files << entry.files.first
    else
      @entries[entry.to_s] = entry
    end
  end
end

TODAY = Date.today

@kols = @entries.values.map(&:name).uniq.sort
@dates = @entries.values.map(&:dates).flatten.uniq.sort

@entries.values.each do |e|
  e.all_dates = e.dates.map do |date|
    [date, @dates.fetch(@dates.index(date) + 1, TODAY)]
  end.flatten.uniq.sort
end

@rows = []
@rows << ["Kol"] + @dates
@entries.values.sort_by { |v| v.dates.min }.each do |entry|
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

series = @entries.values.sort_by { |e| [e.all_dates.size, e.all_dates.first] }.map do |e|
  {name: e.to_s, data: e.all_dates.map { |d| [d.to_time.to_i * 1000, 1] }}
end

puts <<~HTML
  <html>
    <script src="https://code.highcharts.com/highcharts.js"></script>
    <body>
      <div id="container" style="width:100%; height:400px;"></div>
      <script>
        document.addEventListener('DOMContentLoaded', function () {
          const chart = Highcharts.chart('container', {
              title: {
                text: 'Freie Kleingärten'
              },
              legend: {
                enabled: false
              },
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
                },
                series: {
                  marker: {
                    enabled: false,
                    states: {
                      hover: {
                          enabled: false
                      }
                    }
                  }
                }
              },
              series: #{series.to_json}
          });
        });
      </script>
    </body>
  </html>
HTML
