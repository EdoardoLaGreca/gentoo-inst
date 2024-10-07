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

### Basic usage

The script has no [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) in its first line, it was omitted to allow the script to be sourced. However, without a shebang, it can be executed with any shell. Because of that, make sure to **run the script using a [POSIX-compliant shell](https://wiki.archlinux.org/title/Command-line_shell#POSIX_compliant)** in order to avoid any possible misinterpretation of its commands.

The script is split into two parts, namely `part1` and `part2`, which are expected to be executed respectively before and after entering the `chroot` environment. To ensure that no command failed during execution, the user should save the error messages generated by the script in a separate file. By doing so, when the script stops, it is possible to check whether any error occurred and, if that is the case, find the cause. The commands below already save all errors in a separate file called `err.log` by redirecting the script's standard error stream to that file.

Remember to change the script's default values before running it as they may be unsuitable for your system or outdated. The commands below already open the script for editing using `vi` (you can use another text editor, like `nano`). In order to check whether the specified stage file exists, the user should source the script and use the `urlok` function, which takes the URL as argument, prints the HTTP status code, and returns 0 if the URL is valid or 1 if it is not.

```sh
curl -LO --max-redirs 3 https://github.com/EdoardoLaGreca/gentoo-inst.sh/raw/refs/heads/main/gentoo-inst.sh
vi gentoo-inst.sh # edit default values
./gentoo-inst.sh part1 2>err.log
less err.log # any error?
mv gentoo-inst.sh /mnt/gentoo
chroot /mnt/gentoo /bin/bash
./gentoo-inst.sh part2 2>err.log
less err.log # any error?
exit
umount -R /mnt/gentoo
reboot
```

The new root directory, in this case  `/mnt/gentoo`, must be the same as the directoty specified by the `rootdir` variable in the installation script.

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
