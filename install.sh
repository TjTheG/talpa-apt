#!/bin/sh
# Turn Ubuntu 24.04 (GNOME) or Linux Mint 22 (Cinnamon) into Talpa Linux:
#
#   curl -fsSL https://raw.githubusercontent.com/TjTheG/talpa-apt/main/install.sh | sudo sh
#
# Adds the Talpa apt repository (after checking its signing key), installs
# talpa-theme and talpa-apps, and gives the user who ran sudo the Talpa look.
set -eu

REPO=https://raw.githubusercontent.com/TjTheG/talpa-apt/main
KEYRING=/usr/share/keyrings/talpa-archive-keyring.asc
FINGERPRINT=78D9D09E3AC4511C67B7146214F010D16C104170
# Temporary; the talpa-repo package installs the permanent source.
BOOTSTRAP_LIST=/etc/apt/sources.list.d/talpa-bootstrap.list

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mFejl:\033[0m %s\n' "$*" >&2; exit 1; }

# Everything runs from main(), so the whole script is read before any of it
# runs, even when piped from curl.
main() {
    [ "$(id -u)" -eq 0 ] || die "kør med sudo: curl -fsSL $REPO/install.sh | sudo sh"

    # shellcheck disable=SC1091
    . /etc/os-release
    # Ubuntu 24.04, or a distribution built on it such as Linux Mint 22.
    if [ "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}" != noble ]; then
        die "Talpa kræver Ubuntu 24.04 eller Linux Mint 22 (fandt: ${PRETTY_NAME:-ukendt})"
    fi

    export DEBIAN_FRONTEND=noninteractive
    if ! command -v gpg >/dev/null 2>&1; then
        say "Installerer gpg"
        apt-get -o DPkg::Lock::Timeout=600 update </dev/null
        apt-get -o DPkg::Lock::Timeout=600 install -y gpg </dev/null
    fi

    say "Henter og tjekker Talpas signeringsnøgle"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"; rm -f "$BOOTSTRAP_LIST"' EXIT
    curl -fsSL "$REPO/talpa-archive-keyring.asc" -o "$tmp/key.asc"
    got=$(gpg --homedir "$tmp" --show-keys --with-colons "$tmp/key.asc" 2>/dev/null |
        awk -F: '$1 == "fpr" { print $10; exit }')
    [ "$got" = "$FINGERPRINT" ] ||
        die "nøglen har fingerprint '$got', forventede $FINGERPRINT"
    install -m 0644 "$tmp/key.asc" "$KEYRING"

    say "Tilføjer Talpa-repoet og installerer pakkerne"
    echo "deb [signed-by=$KEYRING] $REPO/ ./" > "$BOOTSTRAP_LIST"
    apt-get -o DPkg::Lock::Timeout=600 update </dev/null
    apt-get -o DPkg::Lock::Timeout=600 install -y talpa-theme talpa-apps </dev/null
    rm -f "$BOOTSTRAP_LIST"

    # Apply the look for the desktop user who ran sudo, through their session.
    user=${SUDO_USER:-}
    if [ -n "$user" ] && [ "$user" != root ]; then
        uid=$(id -u "$user")
        bus=/run/user/$uid/bus
        if [ -S "$bus" ]; then
            say "Giver $user Talpa-looket"
            sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
                talpa-apply-look </dev/null || say "Kunne ikke; kør 'talpa-apply-look' selv bagefter"
        else
            say "Kør 'talpa-apply-look' som $user, når du er logget ind"
        fi
    fi

    say "Færdig! Genstart for at se det hele, inkl. boot-skærmen."
    say "Discord og Claude Code installeres i baggrunden, så snart der er netværk."
}

main "$@"
