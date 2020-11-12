![OpenConnect](/openconnect.png)

# OpenConnect Client with tunsocks

* Combines [OpenConnect](https://www.infradead.org/openconnect) and [tunsocks](https://github.com/russdill/tunsocks) projects into a single Docker image
* Exposes HTTP and SOCKS proxies to access VPN resources through the Docker container
* Supports port forwarding

## Usage

Start VPN connection and reconnect if container dies (e.g., VPN disconnects)

    # SOCKS proxy on port 9000; HTTP proxy on 8080; Forward port 1688
    $ docker run -d --restart unless-stopped --name openconnect \
        -p 9000:9000 -p 8080:8080 -p 1688:1688 \
        -e URL="<SSL VPN URL>" \
        -e USERNAME="<VPN username>" \
        -e PASSWORD="<VPN password>" \
        -e TUNSOCKS_OPTS="-L 0.0.0.0:1688:<vpn protected host>:1688" \
        ngucandy/docker-openconnect-tunsocks:latest

Example SSH connection through SOCKS proxy

    $ cat ~/.ssh/config
    Host *.internal.domain.com
      ProxyCommand socat - SOCKS4A:<docker host>:%h:%p,socksport=9000

