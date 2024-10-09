gentoo-inst.sh
==============

My own Gentoo installation script. Remember to edit it before running.

⚠️ Work in progress, wait for the 1.0 release before using.

## Rationale

[Gentoo](https://www.gentoo.org/) is a nice Linux distribution but typing all the commands every time you need to install it is boring and error-prone. Instead of using a script made by someone else, which needs to be firstly understood, secondly checked for errors, and thirdly adapted to one's will, it is faster to write a new script from the ground up. Not only that, writing a Gentoo installation script from scratch is more educational, compared to changing an existing one.

## Merits

- It's short.
- It's written in POSIX shell only.
- It has no external dependencies, other than the preinstalled utilities.
- It's readable.

## Usage

### Basic usage (important!)

The script has no [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) in its first line, it was omitted to allow the script to be sourced. However, without a shebang, it can be executed with any shell. Because of that, make sure to **run the script using a [POSIX-compliant shell](https://wiki.archlinux.org/title/Command-line_shell#POSIX_compliant)** in order to avoid any possible misinterpretation of its commands.

The script is split into two parts, namely `part1` and `part2`, which are expected to be executed respectively before and after entering the `chroot` environment.

Remember that you may need to **change the script's default values** before running it as they may be outdated or unsuitable for your system. One of the commands below opens the script for editing using `vi` for this purpose, although you can use another text editor of your choice.

It is also recommended to check whether the specified stage file exists. This can be done by sourcing the script and using the `stageurl` function to get the complete stage file's URL. Then, the URL can be verified by using the `urlok` function, which takes that same URL as argument, prints the HTTP status code, and returns 0 if the URL is valid or 1 if it is not. The commands below include this part.

```sh
curl -LO --max-redirs 3 https://github.com/EdoardoLaGreca/gentoo-inst.sh/raw/refs/heads/main/{gentoo-inst.sh,rc.conf}
vi gentoo-inst.sh		# edit default values
. ./gentoo-inst.sh
urlok `stageurl`
part1 2>err.log
less err.log			# any error?
rm err.log
mv gentoo-inst.sh rc.conf /mnt/gentoo
chroot /mnt/gentoo /bin/bash
./gentoo-inst.sh part2 2>err.log
less err.log			# any error?
rm gentoo-inst.sh rc.conf err.log
exit
umount -R /mnt/gentoo
reboot
```

To ensure that no error occurred, the commands which run the script's parts save the generated error messages in a separate file called `err.log`. By doing so, when the execution terminates, it is possible to check whether any error occurred and, if that is the case, find the cause.

The new root directory, in this case  `/mnt/gentoo`, must be the same as the directoty specified by the `rootdir` variable in the installation script.

### Granular running and script sourcing

Thanks to the structure of the script, the user can run not only the first and second parts but also every function that the script is made of. To do so is as simple as replacing `part1` and `part2` (see the "Basic usage" section) with the name of any function, followed by its arguments.

For example, if the user wanted to check for their internet connection and mount the root filesystem from the root partition:

```
./gentoo-inst.sh connok
./gentoo-inst.sh mountroot
```

However, it is not possible to pass the output of a function as the argument of another one (like in `urlok \`stageurl\``) because the function producing the output, which is called before reading the script, does not exist at that time. For this reason, and for a matter of convenience, the user can source the script and run any function just by typing them, without the additional script name. The previous example can be re-written as follows:

```
. ./gentoo-inst.sh
connok
mountroot
```

There is a little caveat, though. All functions read values from external variables instead of requiring the caller to pass those values as arguments. This might be fixed in future but for now all the necessary external variables are initialized right before calling any function. <!-- TODO -->

### Adding additional packages and USE flags

The file called "packages" contains a list of packages that I usually install right after the operating system installation. The packages are separated by line breaks and they can be fed into emerge like this:

```
emerge `cat pkgs | tr '\n' ' '`
```

The file called "usef" contains a space-separated list of USE flags that I usually add to `/etc/portage/make.conf`. They are sorted by name for several reasons.

```
newuse=`cat usef`
echo 'USE="$USE '$newuse'"' >/etc/portage/make.conf
```

## Tweaking

Commands are grouped into functions and the script is meant to be understandable and easy to edit. If you want to customize your Gentoo installation, the only way is to edit the script.

Customization options are not provided by default, except for a few variables, for several reasons including, but not limited to, the following:

- The customization options I may provide, regardless of how many they are, may not be enough for the user.
- There is a point in the process of adding customization options where the amount of code that implements those options exceeds the amount of all the other code combined. Surpassing that point is wrong.
- Not implementing any customisation option keeps me sane.

## License

[ISC](LICENSE)
