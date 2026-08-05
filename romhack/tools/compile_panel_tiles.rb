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

abort "compiled tile data must be 192 bytes" unless binary.bytesize == 192
File.binwrite(output_path, binary)

sheet = composite_sheet(images)
write_png(File.join(asset_dir, "panel-starter-8x8.png"), sheet)
write_png(
  File.join(asset_dir, "panel-starter-8x8-preview.png"),
  scale_nearest(sheet, 10)
)