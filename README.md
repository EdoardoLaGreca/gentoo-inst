gentoo-inst.sh
==============

My own Gentoo installation script. Remember to edit it before running.

⚠️ Work in progress, wait for the 1.0 release before using.

## Merits

- It's short.
- It's written in POSIX shell only.
- It has no external dependencies.
- It's readable.

## Usage

```
curl -LO --max-redirs 3 https://github.com/EdoardoLaGreca/gentoo-inst.sh/raw/refs/heads/main/gentoo-inst.sh
. ./gentoo-inst.sh part1
mv gentoo-inst.sh $root/root
chroot $root /bin/bash
. ./gentoo-inst.sh part2
```

There is also a text file called "pkgs" which contains a list of packages that I usually install right after the operating system installation. The packages are separated by line breaks and they can be fed into emerge like this:

```
emerge `cat pkgs | tr '\n' ' '`
```

## Tweaking

Commands are grouped into functions and the script is meant to be understandable and easy to edit. If you want to customize your Gentoo installation, the only way is to edit the script.

Customization options are not provided by default, except for a few variables, for several reasons including, but not limited to, the following:

- The customization options I may provide, regardless of how many they are, may not be enough for the user.
- There is a point in the process of adding customization options where the amount of code that implements those options exceeds the amount of all the other code combined. Surpassing that point is wrong.
- Not implementing any customisation option keeps me sane.

## License

[ISC](LICENSE)
