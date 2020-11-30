# imagewriter

Print black-and-white PNG images to an Apple Imagewriter or ImageWriter II
dot-matrix serial printer.

Written in Ruby.

## Requirements

* Ruby
* Serial adapter connecting to the printer. What works for me:
  Tripp Lite Keyspan USB to DB-9 serial adapter + DB-9 null modem + DB-9
  to Mini DIN-8 cable

## Installing

To install systemwide, use `gem install imagewriter`.

To use from the project directory, run `bundle install` once, then
run `bin/imagewriter` directly.

## Usage

Output is written to STDOUT, and should be redirected to the serial
adapter of your choice.

```
Usage: imagewriter [options] filename.png
Vertical resolution is 144 dpi; horizontal resolution is adjustable.
Max printable width is 8 inches, or 8 * horizontal DPI pixels.
Options:
    -H, --horizontal DPI             Horizontal DPI. One of: 72, 80, 96, 107, 120, 136, 144, 160; default 144
    -q, --quality QUALITY            Print quality. 1 (fastest) to 8 (best); default 1
    -s, --sleep                      Sleep this many seconds between passes. Default 0.75
    -h, --help                       Print this help message to STDERR
```

## Status

Works great 👍

High quality settings take a very long time, but produce lovely output.

## Why

I wanted better output quality and more predictable results than the
CUPS ImageWriter driver provides. The [technical manual for the
ImageWriter II](https://www.apple.asimov.net/documentation/hardware/printers/Apple%20ImageWriter%20II%20Technical%20Reference%20Manual.pdf)
is not hard to come by, so I used it to write this.

## How

It uses the standard interleaved-rows trick to achieve 144 vertical DPI.
Writing 16 rows on each back-and-forth pass is the default and fastest
setting, and matches the operation of extant ImageWriter drivers.
Unsightly horizontal lines are commonly present in the output.

Higher output quality is achieved by writing fewer rows at a time,
and dovetailing the vertical edges of each pass in order to soften the
horizontal artifacts in the finished printout.

## Who, When

Written by Pete Gamache over Thanksgiving weekend, 2020.

## License, or not

This software is released into the public domain.

