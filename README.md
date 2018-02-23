# LAMP 5.3.3-DEV Docker
LAMP 5.3.3 use **ONLY** for development environment


## Services

...TODO...

### Xdebug

...TODO...
 
#### Xdebug with macOS host (Docker for Mac)

Add new alias loopback for localhost

    sudo ifconfig lo0 alias 10.254.254.254 netmask 255.255.255.0

#### Xdebug with Linux host

Add new alias loopback for localhost

Append to file `/etc/network/interfaces`


    auto lo:0
    iface lo:0 inet static
    name Docker loopback
    address 10.254.254.254
    netmask 255.255.255.0