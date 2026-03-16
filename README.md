# Write

Edit text documents.

## Building and Installation

You'll need the following dependencies:

* libgranite-7-dev >= 5.4.0
* libgtk-4-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install` then execute with `io.github.vvvvvvitor.write`

    sudo ninja install
    io.github.vvvvvvitor.write