#!/usr/bin/env ruby
#
# imagewriter
#
# writes a black and white PNG image onto a piece of paper,
# using an Apple Imagewriter or ImageWriter II printer
#
# run `./imagewriter -h` to see options.
#
#  ,  2020 pete gamache pete@gamache.org
# (k) all rights reversed

require 'chunky_png'
require 'optparse'

class ImageWriter
  def initialize(argv)
    parse_argv!(argv.clone)

    @img = ChunkyPNG::Image.from_file(@filename)
    STDERR.puts "#{@filename}: height #{@img.height}, width #{@img.width}"

    printable_width = @hdpi * 8
    if @img.width > printable_width
      STDERR.puts "Warning: image exceeds printable width of #{printable_width} pixels; printout will be clipped"
    end
  end

  def print!
    init_printer!

    if @quality == "regular"
      do_print!(16, 0, :b1_v144_regular, :b2_v144_regular, 1, 15)
    elsif @quality == "enhanced"
      do_print!(12, -4, :b1_v144_enhanced, :b2_v144_enhanced, 1, 11)
    elsif @quality == "best"
      do_print!(4, 0, :b1_v144_best, :b2_v144_best, 1, 3)
    end
  end

@private

  ## Send Esc + this letter to change horizontal DPI
  HORIZ_DPI_CODE = {
    72 => "n",
    80 => "N",
    96 => "E",
    107 => "e",
    120 => "q",
    136 => "Q",
    144 => "p",
    160 => "P"
  }

  ## Send \x1F then this letter to send N line feeds
  LINE_FEEDS = {
    1 => "1",
    2 => "2",
    3 => "3",
    4 => "4",
    5 => "5",
    6 => "6",
    7 => "7",
    8 => "8",
    9 => "9",
    10 => ":",
    11 => ";",
    12 => "<",
    13 => "=",
    14 => ">",
    15 => "?"
  }

  QUALITY = ["regular", "enhanced", "best"]

  def parse_argv!(argv)
    options = {
      hdpi: 144,
      quality: "regular",
      sleep: 0.75
    }

    help = nil
    OptionParser.new do |parser|
      parser.banner = <<-EOT
        Usage: #{$0} [options] filename.png"
        Vertical resolution is 144 dpi; horizontal resolution is adjustable.
        EOT

      dpis = HORIZ_DPI_CODE.keys.join(", ")
      parser.on('-H', '--horizontal DPI', Integer, "Horizontal DPI (one of: #{dpis}; default #{options[:hdpi]})") do |n|
        if HORIZ_DPI_CODE[n]
          options[:hdpi] = n
        else
          STDERR.puts "Bad horizontal DPI setting #{n} (must be one of: #{dpis})\n"
          STDERR.puts parser.to_s
          exit 1
        end
      end

      parser.on("-q", "--quality QUALITY", "Print quality (one of: #{QUALITY.join(", ")}; default #{options[:quality]})") do |n|
        if QUALITY.include?(n)
          options[:quality] = n
        else
          STDERR.puts "Bad quality setting #{n} (must be one of: #{QUALITY.join(", ")})\n"
          STDERR.puts parser
          exit 1
        end
      end

      parser.on("-s", "--sleep", Float, "Sleep this many seconds between passes (default #{options[:sleep]})") do |n|
        options[:sleep] = n
      end

      parser.on("-h", "--help", "Print this help message to STDERR") do
        STDERR.puts parser
        exit
      end

      help = parser.to_s
    end.parse!(argv)

    @hdpi = options[:hdpi]
    @quality = options[:quality]
    @sleep = options[:sleep]

    @filename = argv.shift
    if !@filename
      STDERR.puts "Missing filename\n"
      STDERR.puts help
      exit 1
    end
  end

  def do_print!(lines_per_double_pass, y0, b1_fun, b2_fun, lf1, lf2)
    double_passes = (@img.height / lines_per_double_pass).ceil + 1
    y = y0
    width = [@hdpi * 8, @img.width].min

    0.upto(double_passes) do
      bytes1 = 0.upto(width).map{|x| self.send(b1_fun, x, y)}
      bytes2 = 0.upto(width).map{|x| self.send(b2_fun, x, y)}

      printf "\eG%.4d", width
      bytes1.each{|b| print b.chr}
      printf "\r"

      printf "\x1F%s", LINE_FEEDS[lf1]

      printf "\eG%.4d", width
      bytes2.each{|b| print b.chr}
      printf "\r"

      printf "\x1F%s", LINE_FEEDS[lf2]

      sleep @sleep
      y += lines_per_double_pass
    end
  end

  ### Regular quality: 16 lines per double-pass
  def b1_v144_regular(x, y)
    0 +
      0b00000001 * get(x, y) +
      0b00000010 * get(x, y+2) +
      0b00000100 * get(x, y+4) +
      0b00001000 * get(x, y+6) +
      0b00010000 * get(x, y+8) +
      0b00100000 * get(x, y+10) +
      0b01000000 * get(x, y+12) +
      0b10000000 * get(x, y+14)
  end

  def b2_v144_regular(x, y)
    0 +
      0b00000001 * get(x, y+1) +
      0b00000010 * get(x, y+3) +
      0b00000100 * get(x, y+5) +
      0b00001000 * get(x, y+7) +
      0b00010000 * get(x, y+9) +
      0b00100000 * get(x, y+11) +
      0b01000000 * get(x, y+13) +
      0b10000000 * get(x, y+15)
  end

  ### Enhanced quality: 12 lines per double-pass, 4 dots dovetailed
  def b1_v144_enhanced(x, y)
    0 +
      0b00000001 * get(x, y) +
      0b00000010 * get(x, y+2) +
      0b00000100 * get(x, y+4) +
      0b00001000 * get(x, y+6) +
      0b00010000 * get(x, y+8) +
      0b00100000 * get(x, y+10)
      #0b01000000 * get(x, y+12) +
      #0b10000000 * get(x, y+14)
  end

  def b2_v144_enhanced(x, y)
    0 +
      #0b00000001 * get(x, y+1) +
      #0b00000010 * get(x, y+3) +
      0b00000100 * get(x, y+5) +
      0b00001000 * get(x, y+7) +
      0b00010000 * get(x, y+9) +
      0b00100000 * get(x, y+11) +
      0b01000000 * get(x, y+13) +
      0b10000000 * get(x, y+15)
  end

  ### Best quality: 4 lines per double-pass
  def b1_v144_best(x, y)
    0 +
      0b00000001 * get(x, y) +
      0b00000010 * get(x, y+2)
  end

  def b2_v144_best(x, y)
    0 +
      0b00000001 * get(x, y+1) +
      0b00000010 * get(x, y+3)
  end

  ## Returns 0 for black pixels that exist, 1 otherwise
  def get(x, y)
    x = @img[x, y] & 0xffffff00
    return 0 if x > 0
    1
  rescue
    1
  end

  def init_printer!
    printf "\ef" # forward line feeds
    printf "\e\x6C1" # do not insert carriage return before LF and FF
    printf "\eZ\x80\x00" # no line feed added after CR
    printf "\eT01" # set line feed to 1/144 inch
    printf "\e%s", HORIZ_DPI_CODE[@hdpi]
  end
end

ImageWriter.new(ARGV).print!
