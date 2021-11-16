# .files ![CI](https://github.com/jimseven/dotfiles/workflows/CI/badge.svg)

## :rocket: A development setup in just a few minutes without the hassle

So you got a new :computer: or you just want to do a clean install of the latest macOS but don't have much time setting everything up the way you like it? Well, meet **.files**!

**.files** is a collection of configuration files (dotfiles _duh!_) plus an automated setup to install all the apps and tools to get running in no time.

![](https://raw.githubusercontent.com/jimseven/dotfiles/main/screenshot.png)

## :robot: Automated installation

:warning: Please backup your current settings. They may very well be overwritten!

After you've successfully installed macOS you can just copy & paste this line into the terminal:

```
curl -fsSL https://raw.githubusercontent.com/jimseven/dotfiles/main/scripts/remote-install.sh | bash
```

## :turtle: Manual installation

:warning: Please backup your current settings. They may very well be overwritten!

:bulb: macOS Command Line Tools are **required**. You can install them with:

```
xcode-select --install
```

1. Clone this repo

   ```
   git clone git@github.com:jimseven/dotfiles.git
   ```

2. Install

   ```
   make install
   ```

## :monocle_face: So what the hell is going on?

### Programming language utilities and package managers

- [x] **[Homebrew](https://github.com/Homebrew/brew)** is a package manager that simplifies the installation of software on Apple's macOS operating system and Linux
- [x] **[Git](https://github.com/git/git)** - Even though it is shipped with macOS, the shipped version is often not up to date.
- [x] **[Volta](https://github.com/volta-cli/volta)**'s job is to manage your JavaScript command-line tools, such as `node`, `npm`, `yarn`, or executables shipped as part of JavaScript packages. It is similar to [NVM](https://github.com/nvm-sh/nvm) but faster.

### Terminal Tools

- [x] **[iTerm2](https://github.com/gnachman/iTerm2)** is a replacement for Terminal. It is super fast and looks great.

- [x] **[iTerm2 Material Design](https://github.com/MartinSeeler/iterm2-material-design)** is an iTerm2 color scheme based on Google's Material Design Color Palette.

- [x] **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)** is a framework for managing your Zsh configuration.

- [x] **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** is a theme for Zsh. It emphasizes speed, flexibility and out-of-the-box experience.

- [x] **[Antigen](https://github.com/zsh-users/antigen)** is a small set of functions that help you easily manage your shell (zsh) plugins. It makes installing and integrating zsh plugins super easy.

- [x] **[Command Not Found](https://github.com/Homebrew/homebrew-command-not-found)** reproduces Ubuntu’s command-not-found for Homebrew users on macOS. When you try to use a command that doesn’t exist locally but is available through a package, it will suggest you a command to install it.

- [x] **[z - jump around](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/z)** defines the z command that tracks your most visited directories and allows you to access them with very few keystrokes.

- [x] **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** suggests commands as you type based on history and completions.

- [x] **[zsh-completions](https://github.com/zsh-users/zsh-completions)** are additional completion definitions for Zsh.

- [x] **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)** provides syntax highlighting for the shell zsh. It enables highlighting of commands whilst they are typed at a zsh prompt into an interactive terminal.

### Dev Ops

- [x] **[Docker](https://www.docker.com)** allows you to build, test, and deploy applications quickly. It packages software into standardized units called containers that have everything the software needs to run including libraries, system tools, code, and runtime. You can quickly deploy and scale applications into any environment and know your code will run.

- [x] **[TablePlus](https://tableplus.com)** is a GUI tool for several relational databases including MySQL, PostgreSQL, SQLite & more.

### IDE

- [x] **[Visual Studio Code](https://github.com/microsoft/vscode)** was ranked the [most popular developer environment tool](https://insights.stackoverflow.com/survey/2019#technology-_-most-popular-development-environments) and that rightfully so.

- [x] **[Material Neutral Theme](https://github.com/bernardodsanderson/material-neutral-theme)** is a theme for VS Code that is based on Google's Material Design Color Palette.

- [x] **[Material Icon Theme](https://github.com/PKief/vscode-material-icon-theme)** gets the Material Design icons into VS Code.

- [x] **[VSCode GraphQL](https://github.com/graphql/vscode-graphql)** aims to tightly integrate the GraphQL ecosystem with VSCode for an awesome developer experience.

- [x] **[Docker for Visual Studio Code](https://github.com/microsoft/vscode-docker)** makes it easy to build, manage, and deploy containerized applications from Visual Studio Code.

- [x] **[Rainbow CSV](https://github.com/mechatroner/vscode_rainbow_csv)** highlights CSV and TSV spreadsheet files in different rainbow colors.

- [x] **[YAML Language Support by Red Hat](https://github.com/redhat-developer/vscode-yaml)** provides comprehensive YAML Language support to Visual Studio Code, via the yaml-language-server, with built-in Kubernetes syntax support.

### Productivity Tools

- [x] **[1Password](https://1password.com)** provides a place for users to store various passwords, software licenses, and other sensitive information in a virtual vault that is locked with a PBKDF2-guarded master password.

- [x] **[Google Drive File Stream](https://www.google.com/drive/download/)** allows easy access to Google Drive files and folders without using a web browser.

- [x] **[Notion](https://www.notion.so)** is an all-in-one workspace application that provides components such as databases, kanban boards, wikis, calendars and reminders for the whole team.

- [x] **[Slack](https://slack.com)** is a channel-based messaging platform.

### Browsers

- [x] **[Chrome]()** is most likely the browser with the [highest market share](https://netmarketshare.com/?options=%7B%22filter%22%3A%7B%22%24and%22%3A%5B%7B%22deviceType%22%3A%7B%22%24in%22%3A%5B%22Desktop%2Flaptop%22%5D%7D%7D%5D%7D%2C%22dateLabel%22%3A%22Trend%22%2C%22attributes%22%3A%22share%22%2C%22group%22%3A%22browser%22%2C%22sort%22%3A%7B%22share%22%3A-1%7D%2C%22id%22%3A%22browsersDesktop%22%2C%22dateInterval%22%3A%22Monthly%22%2C%22dateStart%22%3A%222019-11%22%2C%22dateEnd%22%3A%222020-10%22%2C%22segments%22%3A%22-1000%22%7D) world wide across all platforms.

- [x] **[Firefox Developer Edition](https://www.mozilla.org/firefox/developer/)** is tailored for web developers.

### Audio & Video

- [x] **[IINA](https://github.com/iina/iina)** is a lightweight media player based on [mpv](https://github.com/mpv-player/mpv) and designed with modern versions of macOS in mind.

### macOS utilities

- [x] **[Dockutil](https://github.com/kcrawford/dockutil)** is a command line utility for managing macOS dock items.

- [x] **[Keka](https://github.com/aonez/Keka)** is a full featured file archiver.

- [x] **[mas-cli](https://github.com/mas-cli/mas)** is simple command line interface for the Mac App Store that is designed for scripting and automation.

- [x] **[Finicky](https://github.com/johnste/finicky)** is a macOS application that allows you to set up rules that decide which browser is opened for every link or url.

## References

- [Makefile for your dotfiles](https://polothy.github.io/post/2018-10-09-makefile-dotfiles/) - Mark Nielsen
- [Mathias’s dotfiles](https://github.com/mathiasbynens/dotfiles) - Mathias Bynens
- [.files](https://github.com/webpro/dotfiles) - Lars Kappert
- [Dotfiles](https://github.com/martijngastkemper/dotfiles) - Martijn Gastkemper
- [Matt's MacOS dotfiles](https://github.com/mattorb/dotfiles) - Matt Smith
- [macOS defaults list](https://macos-defaults.com) - Yann Bertrand
