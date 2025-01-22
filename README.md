# mtls_distant_browser
Script to set up a browser in a container with mutual TLS (mTLS).

## WHY?
This script relies on [LinuxServer.io](https://docs.linuxserver.io) and their awesome work!

Using a distant browser is great when you have to open a suspicious link, but the issues with the provided configuration on LinuxServer are that it leaves your ports wide open without any means of identification.  
This project introduces a simple Nginx/Docker configuration to support mTLS without requiring a domain name.

## How do I set it up?
**Distribution:** Ubuntu 24.04

### To get it running:

1. **(Optional)** Use the install script (`install.sh`) to ensure Docker and Nginx are installed.

2. Run the following scripts in sequence:
   - `badvpn_to_bin.sh`: Sets up the **BadVPN** utility to enable a VPN-like tunnel for secure communication. It compiles and installs BadVPN binaries to ensure your containerized browser operates in a private and controlled network environment.
   - `ss_x_tor.sh`: Configures **Shadowsocks** and **Tor** to anonymize your network traffic and provide an additional layer of security and privacy when using the browser in the container.
   - `mtls_browser.sh`: 
     - Creates the server and client certificates.
     - Configures Nginx for mTLS.
     - Sets up the browser in the container using Docker.

3. Download your client `.p12` file with `scp` to your machine:
   ```sh
   scp <username>@<ipAddress>:~/<dir>/client.p12 .
   ```

4. Install the certificate on your browser.

5. Connect to your server with your local browser at:
   ```
   https://<your-server-IP-address>
   ```

6. Enjoy and navigate safely.

## Network Architecture Diagram

```mermaid
graph LR
    A[Local Browser] -->|HTTPS + mTLS| B[Nginx Proxy]
    B -->|Encrypted Traffic| C[Dockerized Browser]
    C -->|Proxy Connection| D[Shadowsocks]
    D -->|Anonymized Traffic| E[Tor Network]
    E -->|Exit Node| F[Internet]
    G[BadVPN Tunnel] -.-> B
```

### Key Points:
- **Local Browser** connects to the Nginx Proxy using HTTPS with mTLS for secure authentication.
- **Nginx Proxy** forwards traffic to the Dockerized Browser container.
- **Shadowsocks** acts as a secure proxy, routing traffic through the **Tor Network** for anonymity.
- **BadVPN Tunnel** ensures a secure and private communication channel.


* [Lorris BELUS](https://github.com/Lbelus) - Developer
