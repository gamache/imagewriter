# imagewriter

Print PNG images to an Apple Imagewriter or ImageWriter II

Written in Ruby.

## Installing

Download this project, run `bundle install`, then run `./print.rb` as
follows:

```
Usage: ./print.rb [options] filename.png
    -H, --horizontal DPI             Horizontal DPI (one of: 72, 80, 96, 107, 120, 136, 144, 160; default 144)
    -V, --vertical DPI               Vertical DPI (one of: 72, 144; default 144)
    -q, --quality QUALITY            Print quality (ignored at 72 vertical DPI; one of: regular, enhanced, best; default regular)
    -h, --help                       Display this help message
```

## Status

144 vertical DPI output looks good, 72 vertical DPI works like crap

## Why

I wanted better output quality and more predictable results than the
CUPS ImageWriter driver provides.

## Blame

Written by Pete Gamache in late 2020.

## License, or not

This software is released into the public domain.

