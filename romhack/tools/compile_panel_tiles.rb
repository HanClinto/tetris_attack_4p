#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "zlib"

abort "usage: #{$PROGRAM_NAME} PANELS_JSON OUTPUT_4BPP" unless ARGV.length == 2

json_path, output_path = ARGV
manifest = JSON.parse(File.read(json_path))
panels = manifest.fetch("panels")
abort "exactly five panels are required" unless panels.length == 5

def parse_pixels(panel)
  rows = panel.fetch("starter_8x8")
  abort "#{panel.fetch("name")}: expected eight rows" unless rows.length == 8

  rows.map.with_index do |row, row_index|
    abort "#{panel.fetch("name")}: row #{row_index} must contain eight hex pixels" unless row.match?(/\A[0-9A-Fa-f]{8}\z/)
    row.chars.map { |pixel| pixel.to_i(16) }
  end
end

def encode_4bpp(pixels)
  low_planes = "".b
  high_planes = "".b
  pixels.each do |row|
    planes = [0, 0, 0, 0]
    row.each_with_index do |pixel, column|
      bit = 7 - column
      4.times do |plane|
        planes[plane] |= ((pixel >> plane) & 1) << bit
      end
    end
    low_planes << planes[0] << planes[1]
    high_planes << planes[2] << planes[3]
  end
  low_planes + high_planes
end

def png_chunk(type, data)
  payload = type + data
  [data.bytesize].pack("N") + payload + [Zlib.crc32(payload)].pack("N")
end

def write_png(path, rgba_rows)
  height = rgba_rows.length
  width = rgba_rows.fetch(0).length
  raw = rgba_rows.map { |row| "\x00".b + row.flatten.pack("C*") }.join
  header = [width, height, 8, 6, 0, 0, 0].pack("NNC5")
  png = "\x89PNG\r\n\x1A\n".b
  png << png_chunk("IHDR", header)
  png << png_chunk("IDAT", Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION))
  png << png_chunk("IEND", "".b)
  File.binwrite(path, png)
end

def rgba_pixels(index_rows, palette)
  index_rows.map do |row|
    row.map do |index|
      red, green, blue = palette.fetch(index)
      [red, green, blue, index.zero? ? 0 : 255]
    end
  end
end

def composite_sheet(images)
  background = [24, 16, 48, 255]
  rows = Array.new(8) { Array.new(images.length * 8) { background.dup } }
  images.each_with_index do |image, image_index|
    image.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        rows[y][image_index * 8 + x] = pixel[3].zero? ? background.dup : pixel
      end
    end
  end
  rows
end

def scale_nearest(image, factor)
  image.flat_map do |row|
    scaled_row = row.flat_map { |pixel| Array.new(factor) { pixel.dup } }
    Array.new(factor) { scaled_row.map(&:dup) }
  end
end

asset_dir = File.dirname(json_path)
binary = "\x00".b * 32
images = []

panels.each do |panel|
  pixels = parse_pixels(panel)
  binary << encode_4bpp(pixels)
  palette = panel.fetch("palette_rgb")
  abort "#{panel.fetch("name")}: expected 16 palette colors" unless palette.length == 16
  image = rgba_pixels(pixels, palette)
  images << image
  write_png(File.join(asset_dir, "#{panel.fetch("name")}-8x8.png"), image)
end

panels.each do |panel|
  pixels = parse_pixels(panel).map(&:dup)
  8.times do |index|
    pixels[0][index] = 1
    pixels[7][index] = 1
    pixels[index][0] = 1
    pixels[index][7] = 1
  end
  binary << encode_4bpp(pixels)
end

glyphs = {
  "P" => ["110", "101", "110", "100", "100"],
  "1" => ["010", "110", "010", "010", "111"],
  "2" => ["110", "001", "010", "100", "111"],
  "3" => ["110", "001", "010", "001", "110"],
  "4" => ["101", "101", "111", "001", "001"]
}.freeze

(1..4).each do |player|
  pixels = Array.new(8) { Array.new(8, 0) }
  [glyphs.fetch("P"), glyphs.fetch(player.to_s)].each_with_index do |glyph, glyph_index|
    glyph.each_with_index do |row, row_index|
      row.chars.each_with_index do |pixel, column_index|
        pixels[row_index + 1][glyph_index * 4 + column_index] = pixel.to_i
      end
    end
  end
  binary << encode_4bpp(pixels)
end

vertical_border = Array.new(8) { Array.new(8, 0) }
horizontal_border = Array.new(8) { Array.new(8, 0) }
8.times do |index|
  vertical_border[index][3] = 1
  vertical_border[index][4] = 1
  horizontal_border[3][index] = 1
  horizontal_border[4][index] = 1
end
binary << encode_4bpp(vertical_border)
binary << encode_4bpp(horizontal_border)

status_glyphs = {
  safe: [
    ["111", "101", "101", "101", "111"],
    ["101", "110", "100", "110", "101"]
  ],
  danger: [
    ["010", "010", "010", "000", "010"],
    ["010", "010", "010", "000", "010"]
  ]
}.freeze

status_glyphs.each do |status, glyph_pair|
  pixels = Array.new(8) { Array.new(8, 0) }
  color = status == :safe ? 5 : 2
  glyph_pair.each_with_index do |glyph, glyph_index|
    glyph.each_with_index do |row, row_index|
      row.chars.each_with_index do |pixel, column_index|
        pixels[row_index + 1][glyph_index * 4 + column_index] =
          pixel == "1" ? color : 0
      end
    end
  end
  binary << encode_4bpp(pixels)
end

menu_digit = Array.new(8) { Array.new(8, 0) }
glyphs.fetch("4").each_with_index do |row, row_index|
  row.chars.each_with_index do |pixel, column_index|
    menu_digit[row_index + 1][column_index + 2] = pixel == "1" ? 1 : 0
  end
end
binary << encode_4bpp(menu_digit)

abort "compiled tile data must be 640 bytes" unless binary.bytesize == 640
File.binwrite(output_path, binary)

sheet = composite_sheet(images)
write_png(File.join(asset_dir, "panel-starter-8x8.png"), sheet)
write_png(
  File.join(asset_dir, "panel-starter-8x8-preview.png"),
  scale_nearest(sheet, 10)
)