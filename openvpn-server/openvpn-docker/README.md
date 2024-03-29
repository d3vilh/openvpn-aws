# OpenVPN and OpenVPN WEB UI

Simple OpenVPN instance for EC2 T2-micro based AWS server. 
It does include 2 different Docker containers:
 - OpenVPN Back-End container (openvpn) powered by Alpine linux and 
 - OpenVPN WEB UI Front-End container (openvpn-ui) for managing OpenVPN server.

### Run this image using a `docker-compose.yml` file

```yaml
---
version: "3.5"

services:
    openvpn:
       container_name: openvpn
       build: ./openvpn-docker
       privileged: true
       ports: 
          - "1194:1194/udp"
       environment:
           REQ_COUNTRY: UA
           REQ_PROVINCE: Kyiv
           REQ_CITY: Chayka
           REQ_ORG: CopyleftCertificateCo
           REQ_OU: ShantiShanti
           REQ_CN: MyOpenVPN
       volumes:
           - ./pki:/etc/openvpn/pki
           - ./clients:/etc/openvpn/clients
           - ./config:/etc/openvpn/config
           - ./staticclients:/etc/openvpn/staticclients
           - ./log:/var/log/openvpn
       cap_add:
           - NET_ADMIN
       restart: always
       depends_on:
           - "openvpn-ui"
``` 

Here is how the `Dockerfile` looks like:

```yaml
# Start from Alpine base image
FROM amd64/alpine
LABEL maintainer="Mr.Philipp <d3vilh@github.com>"

# Copy all files in the current directory to the /opt/app directory in the container
COPY . /opt/app
# Set the working directory to /opt/app
WORKDIR /opt/app

RUN apk --no-cache --no-progress upgrade && apk --no-cache --no-progress add bash bind-tools curl ip6tables iptables openvpn easy-rsa
#Install Latest RasyRSA Version
RUN chmod 755 /usr/share/easy-rsa/*

# Add the openssl-easyrsa.cnf file to the easy-rsa directory
ADD openssl-easyrsa.cnf /opt/app/easy-rsa/

# Expose the OpenVPN port (1194/udp)
EXPOSE 1194/udp

# Make all files in the bin directory executable
RUN chmod +x bin/*

# Make the docker-entrypoint.sh script executable
RUN chmod +x docker-entrypoint.sh

# Set the entrypoint to the docker-entrypoint.sh script, passing in the following arguments:
# $REQ_COUNTRY $REQ_PROVINCE $REQ_CITY $REQ_ORG $REQ_OU $REQ_CN
ENTRYPOINT ./docker-entrypoint.sh \
                "$REQ_COUNTRY" \
                "$REQ_PROVINCE" \
                "$REQ_CITY" \
                "$REQ_ORG" \
                "$REQ_OU" \
                "$REQ_CN"
```


Alternatevly you can add OpenVPN-UI container for WEB UI:
```yaml
    openvpn-ui:
       container_name: openvpn-ui
       image: d3vilh/openvpn-ui-amd64:latest
       environment:
           - OPENVPN_ADMIN_USERNAME={{ ovpnui_user }}
           - OPENVPN_ADMIN_PASSWORD={{ ovpnui_password }}
       privileged: true
       ports:
           - "8080:8080/tcp"
       volumes:
           - ./:/etc/openvpn
           - ./db:/opt/openvpn-gui/db
           - ./pki:/usr/share/easy-rsa/pki
       restart: always
```

### Run this image using the Docker itself

First, build the images:
```sh
sudo docker build -t openvpn .
```

Run the OpenVPN image:
```sh
sudo docker run openvpn \
    --expose 1194:1194/udp \
    --mount type=bind,src=./openvpn/pki,dst=/etc/openvpn/pki \
    --mount type=bind,src=./openvpn/clients,dst=/etc/openvpn/clients \
    --mount type=bind,src=./openvpn/config,dst=/etc/openvpn/config \
    --mount type=bind,src=./openvpn/staticclients,dst=/etc/openvpn/staticclients \
    --mount type=bind,src=./openvpn/log,dst=/var/log/openvpn \
    --cap-add=NET_ADMIN \
    --restart=unless-stopped
    --privileged openvpn
```

Run the OpenVPN-UI image
```
docker run \
-v /home/pi/openvpn:/etc/openvpn \
-v /home/pi/openvpn/db:/opt/openvpn-gui/db \
-v /home/pi/openvpn/pki:/usr/share/easy-rsa/pki \
-e OPENVPN_ADMIN_USERNAME='admin' \
-e OPENVPN_ADMIN_PASSWORD='gagaZush' \
-p 8080:8080/tcp \
--privileged local/openvpn-ui
```

Most of documentation can be found in the [main README.md](https://github.com/d3vilh/raspberry-gateway) file, if you want to run it without anything else you'll have to edit the [dns-configuration](https://github.com/d3vilh/raspberry-gateway/blob/master/openvpn/config/server.conf#L20) (which currently points to the PiHole DNS Server) and
if you don't want to use a custom dns-resolve at all you may also want to comment out [this line](https://github.com/d3vilh/raspberry-gateway/blob/master/openvpn/config/server.conf#L39).

## Configuration

**OpenVPN WEB UI** can be accessed on own port (*e.g. http://localhost:8080 , change `localhost` to your EC2's Public or Private IPv4 address*), the default user and password is `admin/gagaZush` preconfigured in `config.yml` which you supposed to [set in](https://github.com/d3vilh/openvpn-aws/blob/master/example.config.yml#L18) `ovpnui_user` & `ovpnui_password` vars, just before the installation.

The volume container will be inicialized by using the official OpenVPN `openvpn_openvpn` image with included scripts to automatically generate everything you need  on the first run:
 - Diffie-Hellman parameters
 - an EasyRSA CA key and certificate
 - a new private key
 - a self-certificate matching the private key for the OpenVPN server
 - a TLS auth key from HMAC security

This setup use `tun` mode, because it works on the widest range of devices. tap mode, for instance, does not work on Android, except if the device is rooted.

The topology used is `subnet`, because it works on the widest range of OS. p2p, for instance, does not work on Windows.

The server config [specifies](https://github.com/d3vilh/openvpn-aws/blob/master/openvpn/config/server.conf#L40) `push redirect-gateway def1 bypass-dhcp`, meaning that after establishing the VPN connection, all traffic will go through the VPN. This might cause problems if you use local DNS recursors which are not directly reachable, since you will try to reach them through the VPN and they might not answer to you. If that happens, use public DNS resolvers like those of OpenDNS (`208.67.222.222` and `208.67.220.220`) or Google (`8.8.4.4` and `8.8.8.8`).

### Generating .OVPN client profiles

Before client cert. generation you need to update the external IP address to your OpenVPN server in OVPN-UI GUI.

For this go to `"Configuration > Settings"`:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_ext_serv_ip1.png" alt="Configuration > Settings" width="350" border="1" />

And then update `"Server Address (external)"` field with your external Internet IP. Then go to `"Certificates"`, enter new VPN client name in the field at the page below and press `"Create"` to generate new Client certificate:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_ext_serv_ip2.png" alt="Server Address" width="350" border="1" />  <img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_New_Client.png" alt="Create Certificate" width="350" border="1" />

To download .OVPN client configuration file, press on the `Client Name` you just created:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_New_Client_download.png" alt="download OVPN" width="350" border="1" />

If you use NAT and different port for all the external connections on your network router, you may need to change server port in .OVPN file. For that, just open it in any text editor (emax?) and update `1194` port with the desired one in this line: `remote 178.248.232.12 1194 udp`.
This line also can be [preconfigured in](https://github.com/d3vilh/openvpn-aws/blob/master/example.config.yml#L23) `config.yml` file in var `ovpn_remote`.

Install [Official OpenVPN client](https://openvpn.net/vpn-client/) to your client device.

Deliver .OVPN profile to the client device and import it as a FILE, then connect with new profile to enjoy your free VPN:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_Palm_import.png" alt="PalmTX Import" width="350" border="1" /> <img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_Palm_connected.png" alt="PalmTX Connected" width="350" border="1" />

### Revoking .OVPN profiles

If you would like to prevent client to use yor VPN connection, you have to revoke client certificate and restart the OpenVPN daemon.
You can do it via OpenVPN WEB UI `"Certificates"` menue, by pressing Revoke red button:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OpenVPN-UI-Revoke.png" alt="Revoke Certificate" width="600" border="1" />

Revoked certificates won't kill active connections, you'll have to restart the service if you want the user to immediately disconnect. It can be done via Portainer or OpenVPN WEB UI from the same `"Certificates"` page, by pressing Restart red button:

<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OpenVPN-UI-Restart.png" alt="OpenVPN Restart" width="600" border="1" />

### OpenVPN client subnets. Guest and Home users

[OpenVPN-AWS'](https://github.com/d3vilh/openvpn-aws/) OpenVPN server uses `10.0.70.0/24` **"Trusted"** subnet for dynamic clients by default and all the clients connected by default will have full access to your AWS Private subnet, as well as external Internet access with EC2 Public IP.
However you can be desired to share VPN access with your friends and restrict access to your AWS Private network for them (so they wont access OpenVPN-UI GUI or other services), but allow to use Internet connection with EC2 Public IP. This type of guest clients needs to live in special **"Guest users"** subnet - `10.0.71.0/24`:

To assign desired subnet policy to the specific client, you have to define static IP address for this client after you generate .OVPN profile.

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default. 

### OpenVPN Pstree structure

All the Server and Client configuration located in Docker volume and can be easely tuned. Here are tree of volume content:

```shell
|-- clients
|   |-- your_client1.ovpn
|-- config
|   |-- client.conf
|   |-- easy-rsa.vars
|   |-- server.conf
|-- db
|   |-- data.db //OpenVPN UI DB
|-- log
|   |-- openvpn.log
|-- pki
|   |-- ca.crt
|   |-- certs_by_serial
|   |   |-- your_client1_serial.pem
|   |-- crl.pem
|   |-- dh.pem
|   |-- index.txt
|   |-- ipp.txt
|   |-- issued
|   |   |-- server.crt
|   |   |-- your_client1.crt
|   |-- openssl-easyrsa.cnf
|   |-- private
|   |   |-- ca.key
|   |   |-- your_client1.key
|   |   |-- server.key
|   |-- renewed
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- reqs
|   |   |-- server.req
|   |   |-- your_client1.req
|   |-- revoked
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- safessl-easyrsa.cnf
|   |-- serial
|   |-- ta.key
|-- staticclients //Directory where stored all the satic clients configuration
```

### Alternative, CLI ways to deal with OpenVPN configuration

To generate new .OVPN profile execute following command. Password as second argument is optional:
```shell
sudo docker exec openvpn bash /opt/app/bin/genclient.sh <name> <?IP?> <?password?>
```

You can find you .ovpn file under `/openvpn/clients/<name>.ovpn`, make sure to check and modify the `remote ip-address`, `port` and `protocol`. It also will appear in `"Certificates"` menue of OpenVPN WEB UI.

Revoking of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/revoke.sh <clientname>
```

Removing of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/rmcert.sh <clientname>
```

Restart of OpenVPN container can be done via the CLI by running following:
```shell
sudo docker-compose restart openvpn
```

To define static IP, go to `~/openvpn/staticclients` directory and create text file with the name of your client and insert into this file ifrconfig-push option with the desired static IP and mask: `ifconfig-push 10.0.71.2 255.255.255.0`.

For example, if you would like to restrict Home subnet access to your best friend Slava, you should do this:

```shell
slava@Ukraini:~/openvpn/staticclients $ pwd
/home/slava/openvpn/staticclients
slava@Ukraini:~/openvpn/staticclients $ ls -lrt | grep Slava
-rw-r--r-- 1 slava heroi 38 Nov  9 20:53 Slava
slava@Ukraini:~/openvpn/staticclients $ cat Slava
ifconfig-push 10.0.71.2 255.255.255.0
```

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default. 

[**OpenVPN**](https://openvpn.net) as a server and **OpenVPN-web-ui** as a WEB UI screenshots:

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Login.png" alt="OpenVPN-UI Login screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Home.png" alt="OpenVPN-UI Home screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Certs.png" alt="OpenVPN-UI Certificates screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Logs.png" alt="OpenVPN-UI Logs screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Config.png" alt="OpenVPN-UI Configuration screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Server-config.png" alt="OpenVPN-UI Server Configuration screen" width="1000" border="1" />

<img src="https://github.com/d3vilh/raspberry-gateway/blob/master/images/OpenVPN-UI-Profile.png" alt="OpenVPN-UI User Profile" width="1000" border="1" />

Build 22.01.2023 by [d3vilh](https://github.com/d3vilh) for small home project.
