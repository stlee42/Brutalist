# Brutalist Mono

This has been forked from [Brutalist Mono](https://github.com/BRUTALISM/Brutalist).

Brutalist Mono is a fork of [DejaVu Sans Mono v2.37](https://github.com/dejavu-fonts/dejavu-fonts) which itself is a fork of [Bitstream Vera Sans Mono v1.10](https://web.archive.org/web/20210314185159/https://www.gnome.org/fonts/).

## Download

Download TrueType fonts (`BrutalistMono.3.001.zip`) from the [releases](https://github.com/stlee42/BrutalistMono/releases) page.

## Specimen

[See what the font looks like.](specimen.md)

## License

Same as DejaVu fonts, see [LICENSE](LICENSE).

## Change Log

See [CHANGELOG.md](CHANGELOG.md).

## Building

To generate the `.ttf` files, run

```
make
```

and find the `.ttf` files in `build` directory. You will need [fontforge](https://fontforge.org) and [ttfautohint](https://freetype.org/ttfautohint/) (alternatively, [ttfautohint-py](https://github.com/fonttools/ttfautohint-py)) installed.

To generate the `.zip` and `.tar.bz2` files that are suitable for distribution, follow the following instructions.

Create a `resources` directory

```
mkdir resources
```

and in that directory, download some files into it.

```
cd resources
wget http://www.unicode.org/Public/UNIDATA/Blocks.txt
wget http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
wget https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/main/fontconfig-main.zip?path=fc-lang
unzip fontconfig-main.zip\?path\=fc-lang
mv fontconfig-main-fc-lang/fc-lang .
rmdir fontconfig-main-fc-lang
cd ..
```

Run `make dist` and the files will be in `dist` directory.

See: [prerequisites](BUILDING.md).
