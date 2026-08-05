#!/usr/bin/env ruby
# frozen_string_literal: true

abort "usage: #{$PROGRAM_NAME} BEFORE AFTER" unless ARGV.length == 2

before = File.binread(ARGV[0])
after = File.binread(ARGV[1])
abort "snapshot lengths differ" unless before.bytesize == after.bytesize

changes = (0...before.bytesize).select do |address|
  before.getbyte(address) != after.getbyte(address)
end

ranges = []
changes.each do |address|
  if ranges.empty? || address > ranges.last.last + 1
    ranges << [address, address]
  else
    ranges.last[1] = address
  end
end

ranges.each do |start_address, end_address|
  bytes = (start_address..end_address).map do |address|
    format("%02X>%02X", before.getbyte(address), after.getbyte(address))
  end
  puts format(
    "%05X-%05X len=%3d %s",
    start_address,
    end_address,
    end_address - start_address + 1,
    bytes.join(" ")
  )
end
