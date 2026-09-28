# talpa-apt

apt repository for Talpa Linux, published automatically from the (private)
TalpaLinux source repository.

Turn Ubuntu 24.04 into Talpa Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/TjTheG/talpa-apt/main/install.sh | sudo sh
```

The installer checks the signing key (fingerprint
`78D9 D09E 3AC4 511C 67B7 1462 14F0 10D1 6C10 4170`), adds this repository
and installs `talpa-theme` and `talpa-apps`. Updates then arrive through
Software Updater.
