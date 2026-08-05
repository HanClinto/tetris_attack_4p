#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "zlib"

abort "usage: #{$PROGRAM_NAME} VRAM CGRAM OUTPUT_DIR" unless ARGV.length == 3

vram_path, cgram_path, output_dir = ARGV
vram = File.binread(vram_path)
cgram = File.binread(cgram_path)
abort "VRAM dump must be 65536 bytes" unless vram.bytesize == 0x10000
abort "CGRAM dump must be 512 bytes" unless cgram.bytesize == 0x0200

FileUtils.mkdir_p(output_dir)

character_base = 0x4000
panels = [
  { name: "panel-a", tiles: [0x0A0, 0x0A1, 0x0A2, 0x0A3], palette: 1 },
  { name: "panel-b", tiles: [0x0A4, 0x0A5, 0x0A6, 0x0A7], palette: 1 },
  { name: "panel-c", tiles: [0x0A8, 0x0A9, 0x0AA, 0x0AB], palette: 1 },
  { name: "panel-d", tiles: [0x0AC, 0x0AD, 0x0AE, 0x0AF], palette: 1 },
  { name: "panel-e", tiles: [0x0B0, 0x0B1, 0x0B2, 0x0B3], palette: 2 }
].freeze

def decode_color(cgram, color_index)
  offset = color_index * 2
  color = cgram.getbyte(offset) | (cgram.getbyte(offset + 1) << 8)
  [
    (((color >> 0) & 0x1F) * 255.0 / 31).round,
    (((color >> 5) & 0x1F) * 255.0 / 31).round,
    (((color >> 10) & 0x1F) * 255.0 / 31).round
  ]
end

def decode_tile(vram, character_base, tile_index)
  offset = character_base + tile_index * 32
  abort format("tile $%03X is outside VRAM", tile_index) if offset + 31 >= vram.bytesize

  Array.new(8) do |row|
    plane0 = vram.getbyte(offset + row * 2)
    plane1 = vram.getbyte(offset + row * 2 + 1)
    plane2 = vram.getbyte(offset + 16 + row * 2)
    plane3 = vram.getbyte(offset + 16 + row * 2 + 1)
    Array.new(8) do |column|
      bit = 7 - column
      ((plane0 >> bit) & 1) |
        (((plane1 >> bit) & 1) << 1) |
        (((plane2 >> bit) & 1) << 2) |
        (((plane3 >> bit) & 1) << 3)
    end
  end
end

def assemble_metatile(vram, character_base, tile_indices)
  tiles = tile_indices.map { |tile| decode_tile(vram, character_base, tile) }
  Array.new(16) do |row|
    tile_row = row / 8
    pixel_row = row % 8
    tiles[tile_row * 2][pixel_row] + tiles[tile_row * 2 + 1][pixel_row]
  end
end

def downscale_by_majority(source)
  Array.new(8) do |row|
    Array.new(8) do |column|
      samples = [
        source[row * 2][column * 2],
        source[row * 2][column * 2 + 1],
        source[row * 2 + 1][column * 2],
        source[row * 2 + 1][column * 2 + 1]
      ]
      visible = samples.reject(&:zero?)
      candidates = visible.empty? ? samples : visible
      counts = Hash.new(0)
      candidates.each { |value| counts[value] += 1 }
      counts.max_by { |value, count| [count, -candidates.index(value)] }.first
    end
  end
end

def png_chunk(type, data)
  payload = type + data
  [data.bytesize].pack("N") + payload + [Zlib.crc32(payload)].pack("N")
end

def write_png(path, rgba_rows)
  height = rgba_rows.length
  width = rgba_rows.fetch(0).length
  raw = rgba_rows.map do |row|
    "\x00".b + row.flatten.pack("C*")
  end.join
  header = [width, height, 8, 6, 0, 0, 0].pack("NNC5")
  png = "\x89PNG\r\n\x1A\n".b
  png << png_chunk("IHDR", header)
  png << png_chunk("IDAT", Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION))
  png << png_chunk("IEND", "".b)
  File.binwrite(path, png)
end

def rgba_pixels(index_rows, palette, transparent_zero)
  index_rows.map do |row|
    row.map do |index|
      red, green, blue = palette.fetch(index)
      [red, green, blue, transparent_zero && index.zero? ? 0 : 255]
    end
  end
end

def composite_sheet(images, cell_width, cell_height)
  background = [24, 16, 48, 255]
  width = images.length * cell_width
  rows = Array.new(cell_height) { Array.new(width) { background.dup } }
  images.each_with_index do |image, image_index|
    image.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        rows[y][image_index * cell_width + x] = pixel[3].zero? ? background.dup : pixel
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

manifest = {
  format: "SNES 4bpp panel metatiles",
  character_base_byte: format("0x%04X", character_base),
  downscale: "2x2 majority; transparent index 0 ignored when possible",
  color_zero_transparent: true,
  panels: []
}
source_images = []
starter_images = []

panels.each do |panel|
  palette = Array.new(16) do |index|
    decode_color(cgram, panel[:palette] * 16 + index)
  end
  source = assemble_metatile(vram, character_base, panel[:tiles])
  starter = downscale_by_majority(source)
  source_rgba = rgba_pixels(source, palette, true)
  starter_rgba = rgba_pixels(starter, palette, true)
  source_images << source_rgba
  starter_images << starter_rgba

  write_png(File.join(output_dir, "#{panel[:name]}-16x16.png"), source_rgba)
  write_png(File.join(output_dir, "#{panel[:name]}-8x8.png"), starter_rgba)

  manifest[:panels] << {
    name: panel[:name],
    source_tiles: panel[:tiles].map { |tile| format("0x%03X", tile) },
    palette_number: panel[:palette],
    palette_rgb: palette,
    source_16x16: source.map { |row| row.map { |pixel| pixel.to_s(16).upcase }.join },
    starter_8x8: starter.map { |row| row.map { |pixel| pixel.to_s(16).upcase }.join }
  }
end

write_png(
  File.join(output_dir, "panel-source-16x16.png"),
  composite_sheet(source_images, 16, 16)
)
write_png(
  File.join(output_dir, "panel-starter-8x8.png"),
  composite_sheet(starter_images, 8, 8)
)
write_png(
  File.join(output_dir, "panel-source-16x16-preview.png"),
  scale_nearest(composite_sheet(source_images, 16, 16), 5)
)
write_png(
  File.join(output_dir, "panel-starter-8x8-preview.png"),
  scale_nearest(composite_sheet(starter_images, 8, 8), 10)
)
File.write(
  File.join(output_dir, "panels.json"),
  JSON.pretty_generate(manifest) + "\n"
)