#!/usr/bin/env ruby
# frozen_string_literal: true

abort "usage: #{$PROGRAM_NAME} PROFILE" unless ARGV.length == 1

data = File.binread(ARGV[0])
abort "profile length is invalid" unless (data.bytesize % 8).zero?

entries = data.unpack("L<*").each_slice(2).map do |address, count|
  [address, count]
end

ranges = []
entries.each do |address, count|
  if ranges.empty? || address > ranges.last[:end] + 1
    ranges << { start: address, end: address, count: count, max: count }
  else
    range = ranges.last
    range[:end] = address
    range[:count] += count
    range[:max] = [range[:max], count].max
  end
end

ranges.sort_by { |range| [-range[:count], range[:start]] }.first(100).each do |range|
  puts format(
    "%05X-%05X len=%4d accesses=%9d max=%7d",
    range[:start],
    range[:end],
    range[:end] - range[:start] + 1,
    range[:count],
    range[:max]
  )
end
