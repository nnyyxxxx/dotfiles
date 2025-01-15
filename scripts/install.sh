#!/bin/sh

declare_variables() {
    RC='\033[0m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    HYPRLAND_DIR="$HOME/dotfiles"
    mkdir -p "$HOME/.config"
    XDG_CONFIG_HOME="$HOME/.config"
    USERNAME=$(whoami)
}

warning_message() {
    if ! command -v pacman; then
        printf "%b\n" "${RED}Automated installation is only available for Arch-based distributions, install manually.${RC}"
        exit 1
    fi
}

move_to_home() {
    cd "$HOME"
}

install_aur_helper() {
    if command -v yay; then
        sudo pacman -Rns yay --noconfirm
    fi

    if ! command -v paru; then
        cd "$HOME"
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
        cd "$HOME"
        rm -rf paru-bin
    fi
}

set_system_operations() {
    sudo sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf
    sudo mkdir -p /usr/share/icons/default
    sudo touch /usr/share/icons/default/index.theme
    sudo sed -i 's/^Inherits=Adwaita$/Inherits=bibata-classic-xcursor/' /usr/share/icons/default/index.theme
    sudo sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/\[multilib\]\nInclude/}' /etc/pacman.conf
}

install_deps() {
    paru -S --needed --noconfirm \
        cava pipes.sh checkupdates-with-aur librewolf-bin \
        python-pywalfox-librewolf spotify vesktop-bin waypaper-git \
        spicetify-cli

    sudo pacman -Rns --noconfirm \
        lightdm gdm lxdm lemurs emptty xorg-xdm ly hyprland-git

    sudo pacman -Syyu --needed --noconfirm \
        cliphist waybar grim slurp hyprpicker hyprpaper bleachbit hyprland fastfetch cpio \
        pipewire ttf-jetbrains-mono-nerd noto-fonts-emoji ttf-liberation ttf-dejavu meson \
        ttf-fira-sans ttf-fira-mono xdg-desktop-portal zip unzip cmake \
        qt5-graphicaleffects qt5-quickcontrols2 noto-fonts-extra noto-fonts-cjk noto-fonts \
        cmatrix gtk3 neovim pamixer mpv feh zsh dash pipewire-pulse easyeffects \
        btop zoxide zsh-syntax-highlighting ffmpeg xdg-desktop-portal-hyprland qt5-wayland \
        hypridle hyprlock qt6-wayland lsd libnotify dunst bat sddm jq python-pywal python-watchdog \
        python xorg-xhost timeshift inotify-tools checkbashisms shfmt fzf alacritty qt5ct qt5 \
        tar gzip bzip2 unrar p7zip unzip ncompress qt6 gnutls lib32-gnutls base-devel gtk2 \
        lib32-gtk2 lib32-gtk3 libpulse lib32-libpulse alsa-lib lib32-alsa-lib gtk4 \
        alsa-utils alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib giflib lib32-giflib \
        libpng lib32-libpng lib32-libxcomposite libxinerama lib32-libxinerama \
        libldap lib32-libldap openal lib32-openal libxcomposite ocl-icd lib32-ocl-icd libva lib32-libva \
        ncurses lib32-ncurses vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd libva lib32-libva \
        gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils sqlite bubblewrap \
        lib32-sqlite vulkan-radeon lib32-vulkan-radeon lib32-mangohud mangohud pavucontrol qt6ct hyperfine \
        lsp-plugins fuzzel polkit-kde-agent
}

setup_cursors() {
    sudo cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" /usr/share/icons/
    sudo cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" /usr/share/icons
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" "$HOME/.local/share/icons"
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" "$HOME/.local/share/icons"
}

backup_configs() {
    find "$HOME" -type l -not -path "$HOME/dotfiles/*" -not -path "$HOME/dotfiles" -exec rm {} +

    configs="nvim gtk-3.0 fastfetch cava hypr waybar alacritty dunst qt5ct qt6ct fuzzel waypaper"

    for config in $configs; do
        mv "$XDG_CONFIG_HOME/$config" "$XDG_CONFIG_HOME/$config-bak"
    done

    mv "$HOME/.zshrc" "$HOME/.zshrc-bak"
    mv "$HOME/.zprofile" "$HOME/.zprofile-bak"
}

setup_sddm() {
    sudo mkdir -p /usr/share/sddm/themes
    sudo cp -R "$HYPRLAND_DIR/extra/sddm/corners" /usr/share/sddm/themes
    sudo ln -sf "$HYPRLAND_DIR/extra/sddm/sddm.conf" /etc/sddm.conf
    sudo systemctl enable sddm
}

setup_zsh() {
    sudo mkdir -p /etc/zsh/
    sudo touch /etc/zsh/zshenv
    echo "export ZDOTDIR=\"$HOME\"" | sudo tee -a /etc/zsh/zshenv
    ln -sf "$HYPRLAND_DIR/extra/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$HYPRLAND_DIR/extra/zsh/.zprofile" "$HOME/.zprofile"
    touch "$HOME/.zlogin" "$HOME/.zshenv"
}

setup_spotify() {
    sudo chmod a+wr /opt/spotify
    sudo chmod a+wr /opt/spotify/Apps -R
    yes | spicetify backup apply
    mkdir -p "$XDG_CONFIG_HOME/spicetify/Themes"
    mkdir -p "$XDG_CONFIG_HOME/spicetify/Extensions"
    cp -R "$HYPRLAND_DIR/extra/spotify/adblock.js" "$XDG_CONFIG_HOME/spicetify/Extensions"
    cp -R "$HYPRLAND_DIR/extra/spotify/Sleek" "$XDG_CONFIG_HOME/spicetify/Themes"
}

setup_nvim() {
    mkdir -p "$HOME/.local/share/nvim/base46"
    touch "$HOME/.local/share/nvim/base46/statusline"
    touch "$HOME/.local/share/nvim/base46/nvimtree"
    touch "$HOME/.local/share/nvim/base46/defaults"
}

create_symlinks() {
    sudo ln -sf "$HYPRLAND_DIR/extra/gtk-3.0/dark-horizon" /usr/share/themes/

    configs="cava fastfetch nvim gtk-3.0 hypr waybar dunst alacritty qt5ct qt6ct fuzzel waypaper"

    for config in $configs; do
        if [ "$config" = "hypr" ]; then
            ln -sf "$HYPRLAND_DIR/$config" "$XDG_CONFIG_HOME/$config"
        else
            ln -sf "$HYPRLAND_DIR/extra/$config" "$XDG_CONFIG_HOME/$config"
        fi
    done

    cp -R "$HYPRLAND_DIR/extra/templates/discord-pywal.css" "$XDG_CONFIG_HOME/wal/templates"
    cp -R "$HYPRLAND_DIR/extra/templates/alacritty.toml" "$XDG_CONFIG_HOME/wal/templates"
}

setup_system() {
    systemctl --user enable pipewire
    systemctl --user enable pipewire-pulse
    sudo ln -sf /bin/dash /bin/sh
    sudo usermod -s /bin/zsh "$USERNAME"
    mkdir -p "$HOME/Documents"
}

setup_configurations() {
    setup_cursors
    backup_configs
    setup_sddm
    setup_zsh
    setup_spotify
    wal -i "$HYPRLAND_DIR/wallpapers/baddie.png"
    setup_nvim
    create_symlinks
    setup_system
    pywalfox install --browser librewolf
}

setup_sddm_pfp() {
    sudo mkdir -p /var/lib/AccountsService/icons/
    sudo cp "$HYPRLAND_DIR/pfps/cutie.jpg" "/var/lib/AccountsService/icons/$USERNAME"
    sudo mkdir -p /var/lib/AccountsService/users/
    echo "[User]" | sudo tee "/var/lib/AccountsService/users/$USERNAME" >/dev/null
    echo "Icon=/var/lib/AccountsService/icons/$USERNAME" | sudo tee -a "/var/lib/AccountsService/users/$USERNAME" >/dev/null
}

success_message() {
    printf "%b\n" "${GREEN}Installation complete.${RC}"
}

declare_variables
warning_message
move_to_home
install_aur_helper
set_system_operations
install_deps
setup_configurations
setup_sddm_pfp
success_message
