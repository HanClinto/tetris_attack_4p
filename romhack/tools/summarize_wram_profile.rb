#!/usr/bin/env ruby
# frozen_string_literal: true

abort "usage: #{$PROGRAM_NAME} PROFILE START_SNAPSHOT END_SNAPSHOT" unless ARGV.length == 3

profile_data = File.binread(ARGV[0])
abort "profile length is invalid" unless (profile_data.bytesize % 8).zero?
entries = profile_data.unpack("L<*").each_slice(2).map do |address, writes|
  [address, writes]
end

start_data = File.binread(ARGV[1])
end_data = File.binread(ARGV[2])

ranges = []
entries.each do |address, writes|
  if ranges.empty? || address > ranges.last[:end] + 1
    ranges << {
      start: address,
      end: address,
      writes: writes,
      max_writes: writes,
      changed: start_data.getbyte(address) != end_data.getbyte(address) ? 1 : 0
    }
  else
    range = ranges.last
    range[:end] = address
    range[:writes] += writes
    range[:max_writes] = [range[:max_writes], writes].max
    range[:changed] += 1 if start_data.getbyte(address) != end_data.getbyte(address)
  end
end

ranges.sort_by { |range| [-range[:writes], range[:start]] }.first(80).each do |range|
  puts format(
    "%05X-%05X len=%4d writes=%8d max=%6d changed=%4d",
    range[:start],
    range[:end],
    range[:end] - range[:start] + 1,
    range[:writes],
    range[:max_writes],
    range[:changed]
  )
end
