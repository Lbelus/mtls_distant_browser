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
scp <username>@<ipAddress>:~/b_in_c/client.p12 .
```
4. Install the cert on your browser;

5. Connect to your server with at https://<your-IP-address>

6. Enjoy and navigate safely.

* [Lorris BELUS](//github.com/Lbelus) - Developer
