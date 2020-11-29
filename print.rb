#!/usr/bin/env ruby
require 'chunky_png'
require 'optparse'


class ImageWriter
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

  QUALITY = ["regular", "enhanced", "best"]

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

  def parse_argv!(argv)
    options = {
      hdpi: 144,
      vdpi: 144,
      quality: "regular",
    }

    help = nil
    OptionParser.new do |parser|
      parser.banner = "Usage: #{$0} [options] filename.png"

      dpis = HORIZ_DPI_CODE.keys.join(", ")
      parser.on('-H', '--horizontal DPI', Integer, "Horizontal DPI (one of: #{dpis}; default #{options[:hdpi]})") do |n|
        if HORIZ_DPI_CODE[n]
          options[:hdpi] = n
        else
          STDERR.puts "Bad horizontal DPI setting #{n} (must be one of: #{dpis})"
          STDERR.puts(parser.to_s)
          exit 1
        end
      end

      parser.on("-V", "--vertical DPI", Integer, "Vertical DPI (one of: 72, 144; default #{options[:vdpi]})") do |n|
        if n == 72 || n == 144
          options[:vdpi] = n
        else
          STDERR.puts "Bad vertical DPI setting #{n} (must be one of : 72, 144)"
          STDERR.puts(parser.to_s)
          exit 1
        end
      end

      parser.on("-q", "--quality QUALITY", "Print quality (ignored at 72 vertical DPI; one of: #{QUALITY.join(", ")}; default #{options[:quality]})") do |n|
        if QUALITY.include?(n)
          options[:quality] = n
        else
          STDERR.puts "Bad quality setting #{n} (must be one of: #{QUALITY.join(", ")})"
          STDERR.puts(parser.to_s)
          exit 1
        end
      end

      parser.on("-h", "--help", "Display this help message") do
        STDERR.puts(parser.to_s)
        exit
      end

      help = parser.to_s
    end.parse!(argv)

    @hdpi = options[:hdpi]
    @vdpi = options[:vdpi]
    @quality = options[:quality]
    @filename = argv.shift

    if !@filename
      STDERR.puts "Missing filename"
      STDERR.puts help
      exit 1
    end
  end

  def initialize(argv)
    parse_argv!(argv.clone)

    @img = ChunkyPNG::Image.from_file(@filename)
    STDERR.puts "#{@filename}: height #{@img.height}, width #{@img.width}"

    printable_width = @hdpi * 8
    if @img.width > printable_width
      STDERR.puts "Warning: image exceeds printable width of #{printable_width} pixels"
    end

    init_printer

    if @vdpi == 72
      print_v72
    elsif @quality == "regular"
      print_v144(16, 0, :b1_v144_regular, :b2_v144_regular, 1, 15, 0.75)
    elsif @quality == "enhanced"
      print_v144(12, -4, :b1_v144_enhanced, :b2_v144_enhanced, 1, 11, 0.75)
    elsif @quality == "best"
      print_v144(4, 0, :b1_v144_best, :b2_v144_best, 1, 3, 0.75)
    end
  end

  def print_v72
    passes = (@img.height / 8).ceil
    y = 0
    width = [@hdpi * 8, @img.width].min

    0.upto(passes) do
      bytes = 0.upto(width).map{|x| b1_v72(x, y)}

      printf "\r"
      printf "\eG%.4d", width
      bytes.each{|b| print b.chr}

      printf "\x1F8\x1F8"

      sleep 0.75

      y += 8
    end
  end

  def print_v144(lines_per_double_pass, y0, b1_fun, b2_fun, lf1, lf2, naptime)
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

      sleep naptime
      y += lines_per_double_pass
    end
  end


  #### Regular quality: 16 lines per double-pass
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

  #### Enhanced quality: 12 lines per double-pass, interleaved by 4 dots
  def b1_v144_enhanced(x, y)
    0 +
      0b00000001 * get(x, y) +
      0b00000010 * get(x, y+2) +
      0b00000100 * get(x, y+4) +
      0b00001000 * get(x, y+6) +
      0b00010000 * get(x, y+8) +
      0b00100000 * get(x, y+10) #+
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

  #### Best quality: 4 lines per double-pass
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

  #### 72 dpi
  def b1_v72(x, y)
    0 +
      0b00000001 * get(x, y) +
      0b00000010 * get(x, y+1) +
      0b00000100 * get(x, y+2) +
      0b00001000 * get(x, y+3) +
      0b00010000 * get(x, y+4) +
      0b00100000 * get(x, y+5) +
      0b01000000 * get(x, y+6) +
      0b10000000 * get(x, y+7)
  end

  ## Returns 0 for black pixels that exist, 1 otherwise
  def get(x, y)
    x = @img[x, y] & 0xffffff00
    return 0 if x > 0
    1
  rescue
    1
  end

  def init_printer
    printf "\ef" # forward line feeds
    printf "\e\x6C1" # do not insert carriage return before LF and FF
    printf "\eZ\x80\x00" # no line feed added after CR
    printf "\eT01" # set line feed to 1/144 inch
    printf "\e%s", HORIZ_DPI_CODE[@hdpi]
  end
end

ImageWriter.new(ARGV)
