#!/usr/bin/env ruby

require "bundler/setup"

require "git"
require "json"

mapping = {}
Git.open(".").log(100).each do |commit|
  commit.diff_parent.map do |diff|
    if diff.path.include?("pdf")
      mapping[diff.path] ||= []
      mapping[diff.path] << commit.date
    end
  end
end

puts mapping.to_json
