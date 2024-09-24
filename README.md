gentoo-inst.sh
==============

My own Gentoo installation script.

## Merits

- It's lightweight.
- It's written in POSIX shell only.
- It has no external dependencies.
- It's readable.

## Usage

```
curl -O https://github.com/EdoardoLaGreca/gentoo-inst.sh/raw/refs/heads/main/gentoo-inst.sh
sudo ./gentoo-inst.sh
```

## Tweaking

Commands are grouped into functions and the script is meant to be understandable and easy to edit. If you want to customize your Gentoo installation, the only way is to edit the script.

Customization options are not provided by default for several reasons including, but not limited to, the following:

- The customization options I may provide, regardless of how many they are, may not be enough for the user.
- There is a point in the process of adding customization options where the amount of code that implements those options exceeds the amount of all the other code combined. Surpassing that point is wrong.
- Not implementing any customisation option keeps me sane.

## License

[ISC](LICENSE)
