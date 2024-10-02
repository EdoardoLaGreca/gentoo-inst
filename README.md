gentoo-inst.sh
==============

My own Gentoo installation script. Remember to edit it before running.

⚠️ Work in progress, wait for the 1.0 release before using.

## Rationale

Gentoo is a nice Linux distribution but typing all the commands every time you need to install it is boring and error-prone. Instead of using a script made by someone else, which needs to be firstly understood, secondly checked for errors, and thirdly adapted to one's will, it is faster to write a new script from the ground up. Not only that, writing a Gentoo installation script from scratch is more educational, compared to changing an existing one.

## Merits

- It's short.
- It's written in POSIX shell only.
- It has no external dependencies, other than the preinstalled utilities.
- It's readable.

## Usage

### Basic usage

The most common usage of the script is the following. First of all, the user downloads the script locally using `curl`. Then, they run the first part, which, barring errors, ends when the `chroot` environment is correctly set up. After that, the user both moves the script to the new environment and enters into it using `chroot`. Finally, the user runs the script again for the second part.

The script is made to be sourced so it lacks a shebang line at the beginning. However, without the shebang, it can be executed with any shell. For this reason, it is necessary to **run the script with a POSIX-compliant shell** to avoid any possible misinterpretation of its commands.

```
curl -LO --max-redirs 3 https://github.com/EdoardoLaGreca/gentoo-inst.sh/raw/refs/heads/main/gentoo-inst.sh
./gentoo-inst.sh part1
mv gentoo-inst.sh $root/root
chroot $root /bin/bash
./gentoo-inst.sh part2
```

### Granular running and script sourcing

Thanks to the structure of the script, the user can run not only the first and second parts but also every function that the script is made of. To do so is as simple as replacing `part1` and `part2` (see the "Basic usage" section) with the name of any function.

For example, if the user wanted to check for their internet connection and mount the root filesystem from the root partition:

```
./gentoo-inst.sh connok
./gentoo-inst.sh mountroot
```

Not only that, the user can source the script and run any function just by typing them, without the additional script name. The previous example can be re-written as follows:

```
. ./gentoo-inst.sh
connok
mountroot
```

### Installing additional packages

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
