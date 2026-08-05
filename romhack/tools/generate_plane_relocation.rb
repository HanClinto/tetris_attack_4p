#!/usr/bin/env ruby
# frozen_string_literal: true

abort "usage: #{$PROGRAM_NAME} ROM TRACE [TRACE...]" unless ARGV.length >= 2

rom_path = ARGV.shift
rom = File.binread(rom_path)
old_base = 0x0F7C
old_end = 0x117B
delta = 0x0200

absolute_operand_opcodes = [
  0x0C, 0x0D, 0x0E, 0x1C, 0x1D, 0x1E,
  0x2C, 0x2D, 0x2E, 0x3C, 0x3D, 0x3E,
  0x4C, 0x4D, 0x4E, 0x5C, 0x5D, 0x5E,
  0x6C, 0x6D, 0x6E, 0x7C, 0x7D, 0x7E,
  0x8C, 0x8D, 0x8E, 0x99, 0x9C, 0x9D, 0x9E,
  0xAC, 0xAD, 0xAE, 0xB9, 0xBC, 0xBD, 0xBE,
  0xCC, 0xCD, 0xCE, 0xD9, 0xDC, 0xDD, 0xDE,
  0xEC, 0xED, 0xEE, 0xF9, 0xFC, 0xFD, 0xFE
].freeze

long_operand_opcodes = [
  0x0F, 0x1F, 0x2F, 0x3F, 0x4F, 0x5F, 0x6F, 0x7F,
  0x8F, 0x9F, 0xAF, 0xBF, 0xCF, 0xDF, 0xEF, 0xFF
].freeze

def lorom_offset(address)
  bank = (address >> 16) & 0xFF
  bank_address = address & 0xFFFF
  return nil if bank_address < 0x8000

  ((bank & 0x7F) * 0x8000) + (bank_address & 0x7FFF)
end

pcs = ARGV.flat_map do |trace_path|
  File.readlines(trace_path, chomp: true).map do |line|
    match = line.match(/\bpc=\$(\h{6})\b/)
    match && match[1].to_i(16)
  end.compact
end.uniq.sort

patches = []
rejected = []
pcs.each do |pc|
  instruction = nil

  absolute_pc = pc - 3
  absolute_offset = lorom_offset(absolute_pc)
  if absolute_offset && absolute_offset + 2 < rom.bytesize
    opcode = rom.getbyte(absolute_offset)
    operand = rom.getbyte(absolute_offset + 1) |
      (rom.getbyte(absolute_offset + 2) << 8)
    if absolute_operand_opcodes.include?(opcode) &&
        (old_base..old_end).cover?(operand)
      instruction = [absolute_pc, operand]
    end
  end

  if instruction.nil?
    long_pc = pc - 4
    long_offset = lorom_offset(long_pc)
    if long_offset && long_offset + 3 < rom.bytesize
      opcode = rom.getbyte(long_offset)
      operand = rom.getbyte(long_offset + 1) |
        (rom.getbyte(long_offset + 2) << 8)
      bank = rom.getbyte(long_offset + 3)
      if long_operand_opcodes.include?(opcode) && bank == 0x7E &&
          (old_base..old_end).cover?(operand)
        instruction = [long_pc, operand]
      end
    end
  end

  if instruction.nil?
    rejected << pc
    next
  end

  instruction_pc, operand = instruction
  patches << [instruction_pc, operand, operand + delta]
end

puts "; Generated from Mesen execution traces."
puts "; Relocates two color-plane contexts from $%04X-$%04X to $%04X-$%04X." % [
  old_base,
  old_end,
  old_base + delta,
  old_end + delta
]
patches.each do |pc, old_operand, new_operand|
  puts
  puts "org $%06X" % (pc + 1)
  puts "    dw $%04X ; was $%04X" % [new_operand, old_operand]
end

warn "generated #{patches.length} patches; rejected #{rejected.length} candidates"
rejected.each do |pc|
  warn "rejected callback pc=$%06X" % pc
end