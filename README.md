# BunnyTweak

Tweak to inject [Bunny](https://github.com/pyoncord/Bunny) into Discord. Forked [VendettaTweak](https://github.com/vendetta-mod/VendettaTweak), modified to match with [BunnyXposed](https://github.com/pyoncord/BunnyXposed) behavior. \
There are still slight differences between these two.

> [!WARNING]
> When sideloading with an Apple Developer Account, some functionality will break. If you value these features, sideload with a local development certificate instead. There is a workaround available that fixes several of the issues. See below for details.

<details>
<summary>Issues & Workaround</summary>
<br/>
To resolve the fixable issues, you need to match the app's bundle ID with your provisioning profile's App ID (excluding the team ID prefix):
<table>
<tr>
    <th>Issue</th>
    <th>Fixable</th>
    <th>Example</th>
</tr>
<tr>
    <td>Cannot change app icons</td>
    <td>✓</td>
    <td rowspan="5"><img src="https://adriancastro.dev/e0hbonxknepw.jpg" width="300"></td>
</tr>
<tr>
    <td>Cannot select items via Files app</td>
    <td>✓</td>
</tr>
<tr>
    <td>Cannot share items to Discord</td>
    <td>✗</td>
</tr>
<tr>
    <td>Cannot use passkeys</td>
    <td>✗</td>
</tr>
</table>

## Doing this will break notifications if the app is backgrounded or closed

</details>

## Installation

Builds can be found in the [Releases](https://github.com/pyoncord/BunnyTweak/releases/latest) tab.

> [!NOTE]
> Decrypted IPAs are sourced from the [Enmity](https://github.com/enmity-mod/) community. These are also used throughout Enmity related projects such as [enmity-mod/tweak](https://github.com/enmity-mod/tweak/) and [acquitelol/rosiecord](https://github.com/acquitelol/rosiecord).\
> All credits are attributed to the owner(s).

### Jailbroken

1. Install Bunny by downloading the appropriate Debian package (or by building your own, see [Building](#building)) and adding it to your package manager. Use the file ending in `arm.deb` for rootful jailbreaks, and the file ending in `arm64.deb` for rootless jailbreaks.

### Jailed

<a href="https://tinyurl.com/24zjszuf"><img src="https://i.imgur.com/dsbDLK9.png" width="230"></a>
<a href="https://tinyurl.com/yh455zk6"><img src="https://i.imgur.com/46qhEAv.png" width="230"></a>

> [!NOTE]
> TrollStore may display an encryption warning, which you can disregard.

1. Download and install [Bunny.ipa](https://github.com/pyoncord/BunnyTweak/releases/latest/download/Bunny.ipa) using your preferred sideloading method.

## Building

<details>
<summary>Instructions</summary>

> These steps assume you use macOS.

1. Install Xcode from the App Store. If you've previously installed the `Command Line Utilities` package, you will need to run `sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer` to make sure you're using the Xcode tools instead.

> If you want to revert the `xcode-select` change, run `sudo xcode-select -switch /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`

2. Install the required dependencies. You can do this by running `brew install make ldid` in your terminal. If you do not have brew installed, follow the instructions [here](https://brew.sh/).

3. Setup your path accordingly. We recommend you run the following before running the next commands, as well as any time you want to build BunnyTweak.

```bash
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"
# feel free to set whatever path you want, but it needs to be a direct path, without relative parts
export THEOS="/Users/vendetta/IPA/theos"
```

4. Setup [theos](https://theos.dev/docs/installation-macos) by running the script provided by theos.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

If you've already installed theos, you can run `$THEOS/bin/update-theos` to make sure it's up to date.

5. Clone this repository with `git clone git@github.com:pyoncord/BunnyTweak.git` and `cd` into it. Replace the URL with your fork if you've forked this repository.

6. To build BunnyTweak, you can run `rm -rf packages && make clean && make package FINALPACKAGE=1 && make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`. The first command will remove any previous packages, the second will clean the project, the third will build the rootful package (which is denoted by the `arm.deb` ending), and the fourth will build the rootless package (which is denoted by the `arm64.deb` ending).

The first time you run this, it might take a bit longer, but subsequent builds should be much faster.

The resulting `.deb` files will be in the `packages` folder. As a reminder, `*arm.deb` is for rootful jailbreaks and sideloading, and `*arm64.deb` is for rootless jailbreaks.

</details>

## Contributors

[![Contributors](https://contrib.rocks/image?repo=bunny-mod/BunnyTweak)](https://github.com/bunny-mod/BunnyTweak/graphs/contributors)

<!-- @vladdy was here, battling all these steps so you don't have to. Have fun! :3 -->
<!-- @castdrian also was here simplifying these steps immensely -->
