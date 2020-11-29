#!/usr/bin/env ruby
require 'chunky_png'

## ImageWriter II driver with two-pass high-res mode
## Input file is B&W PNG max 1152 pixels (144 dpi horiz)
## Usage: ./image.rb file.png >> /dev/ttyUSB0

class ImageWriter
  class << self
    def get(image, x, y)
      x = image[x, y] & 0xffffff00
      return 0 if x > 0
      1
    rescue
      1
    end

    def get_b1(image, x, y)
      0 +
        0b00000001 * get(image,x,y) +
        0b00000010 * get(image,x,y+2) +
        0 * 0b00000100 * get(image,x,y+4) +
        0 * 0b00001000 * get(image,x,y+6) +
        0 * 0b00010000 * get(image,x,y+8) +
        0 * 0b00100000 * get(image,x,y+10) +
        0 * 0b01000000 * get(image,x,y+12) +
        0 * 0b10000000 * get(image,x,y+14)
    end

    def get_b2(image, x, y)
      0 +
        0b00000001 * get(image,x,y+1) +
        0b00000010 * get(image,x,y+3) +
        0 * 0b00000100 * get(image,x,y+5) +
        0 * 0b00001000 * get(image,x,y+7) +
        0 * 0b00010000 * get(image,x,y+9) +
        0 * 0b00100000 * get(image,x,y+11) +
        0 * 0b01000000 * get(image,x,y+13) +
        0 * 0b10000000 * get(image,x,y+15)
    end
  end

  def initialize(filename)
    @img = ChunkyPNG::Image.from_file(filename)
    STDERR.puts "#{@img.height} height, #{@img.width} width"
  end

  def print!
    img = @img
    lines_per_double_pass = 4

    double_passes = (img.height / lines_per_double_pass).ceil

    printf "\eT01" # set line to 1/144 inch

    printf "\ef" # forward line feeds

    printf "\e\x6C1" # do not insert carriage return before LF and FF
    printf "\eZ\x80\x00" # no line feed added after CR

    #printf "\eP" # 160 horizontal DPI
    printf "\ep" # 144 horizontal DPI

    y = 0
    0.upto(double_passes) do
      bytes1 = 0.upto(img.width).map{|x| self.class.get_b1(img, x, y)}
      bytes2 = 0.upto(img.width).map{|x| self.class.get_b2(img, x, y)}

      printf "\eG%.4d", img.width
      bytes1.each{|b| print b.chr}
      printf "\r"

      printf "\x1F1" # one line feed

      printf "\eG%.4d", img.width
      bytes2.each{|b| print b.chr}
      printf "\r"

      #printf "\x1F?" # 15 line feeds
      #printf "\x1F;" # 11 line feeds
      printf "\x1F3" # 3 line feeds

      sleep 0.75
      y += lines_per_double_pass
    end
  end
end

ImageWriter.new(ARGV.shift).print!()
