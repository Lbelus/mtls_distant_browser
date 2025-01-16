# mtls_distant_browser
Script to setup a browser in container with mtls.

## WHY ? 
This script relies on https://docs.linuxserver.io and their awesome work !

Using a distant browser is great when you have to open a suspicious link, but the issues with the provided configuration on linuxserver is that it let your ports wide open without any means of identification;
It's a simple Nginx/docker configuration to support mtls without having to own a domain name; 

## How do i set it up ?
##### Distribution: Ubuntu 24.04

### To get it running: 

1. (Optionnal) Use the install script if you do not have docker and Nginx installed;

2. Simply run the script to:
- Create the server and client certificates;
- Setup the nginx configuration
- Setup the browser in container with docker;

3. Download your client p12 file with scp to your machine;  
```sh
scp <username>@<ipAddress>:~/<dir>/client.p12 .
```
4. Install the cert on your browser;

5. Connect to your server with your local browser at: 
```
https://<your-server-IP-address>
```

6. Enjoy and navigate safely.


## Option run your traffic through SOCKS5 proxy

Source : 
- https://shadowsocks.org/
- https://github.com/shadowsocks
- https://github.com/shadowsocks/badvpn

1. On a separate server, install shadowsock: 
```
apt update
apt install shadowsocks-libev
```
2. initiate the server: 
```
ss-server -s 0.0.0.0 -p 8388 -k yourpassword -m aes-256-gcm
```

Use badvpn as a client instead of the classic shadowsock client


* [Lorris BELUS](//github.com/Lbelus) - Developer
