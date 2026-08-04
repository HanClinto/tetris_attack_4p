#!/usr/bin/env ruby
# frozen_string_literal: true

abort "usage: #{$PROGRAM_NAME} DUMP MAP_BYTE_OFFSET [WIDTH]" unless (2..3).cover?(ARGV.length)

data = File.binread(ARGV[0])
map_offset = Integer(ARGV[1], 0)
width = ARGV[2] ? Integer(ARGV[2], 0) : 32
abort "width must be 32 or 64" unless [32, 64].include?(width)
map_size = width == 64 ? 0x1000 : 0x800
abort "map is outside dump" unless map_offset.between?(0, data.bytesize - map_size)

32.times do |row|
  entries = width.times.map do |column|
    screen_offset = column >= 32 ? 0x800 : 0
    screen_column = column % 32
    offset = map_offset + screen_offset + (row * 32 + screen_column) * 2
    entry = data.getbyte(offset) | (data.getbyte(offset + 1) << 8)
    tile = entry & 0x03FF
    palette = (entry >> 10) & 0x07
    format("%03X:%d", tile, palette)
  end
  puts format("%02d %s", row, entries.join(" "))
end
