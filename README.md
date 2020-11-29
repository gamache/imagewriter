# imagewriter

Print PNG images to an Apple Imagewriter or ImageWriter II

Written in Ruby.

## Requirements

* Ruby
* Serial adapter connecting to the printer. What works for me:
  Tripp Lite Keyspan USB to DB-9 serial adapter + DB-9 null modem + DB-9
  to Mini DIN-8 cable

## Installing

`gem install imagewriter`

## Usage

Output is written to STDOUT, and should be redirected to the serial
adapter of your choice.

```
Usage: imagewriter [options] filename.png"
Vertical resolution is 144 dpi; horizontal resolution is adjustable.
Max printable width is 8 inches, or 8 * horizontal DPI pixels.
Options:
    -H, --horizontal DPI             Horizontal DPI (one of: 72, 80, 96, 107, 120, 136, 144, 160; default 144)
    -q, --quality QUALITY            Print quality (one of: regular, enhanced, best; default regular)
    -s, --sleep                      Sleep this many seconds between passes (default 0.75)
    -h, --help                       Print this help message to STDERR
```

## Status

`regular` works fine but leaves the characteristic horizontal streaks
you remember from childhood.

`enhanced` looks much nicer than and is almost as fast as `regular`.
Currently there's a garbage `?` at the end of each pass (PRs welcome!).

`best` looks fantastic but takes forever.

## Why

I wanted better output quality and more predictable results than the
CUPS ImageWriter driver provides. The [technical manual for the
ImageWriter II](https://www.apple.asimov.net/documentation/hardware/printers/Apple%20ImageWriter%20II%20Technical%20Reference%20Manual.pdf)
is not hard to come by, so I used it to write this.

## Who, When

Written by Pete Gamache over Thanksgiving weekend, 2020.

## License, or not

This software is released into the public domain.

