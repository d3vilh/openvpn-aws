# OpenVPN AWS

**OpenVPN instance**. Which includes 
[**OpenVPN container**](https://github.com/d3vilh/openvpn-aws/tree/master/openvpn/openvpn-docker) with simple [**WEB UI**](https://github.com/d3vilh/openvpn-ui).


# Requirements
- [**Amazon AWS EC2 T2 Micro Instance**](https://aws.amazon.com/ec2/instance-types/t2/) 1x CPU Core, 1Gb RAM
- [**Amazon AWS Debian amd64 AMI**](https://wiki.debian.org/Cloud/AmazonEC2Image/Bullseye) Debian Bullseye
- **At least 8Gb GP2 Storage**
- **Opened UDP/1194 and TCP/8080** ports (TCP/8080 necessary for [OpenVPN-UI](https://github.com/d3vilh/openvpn-ui) initial configuration only)
> Theoretically [OpenVPN AWS](https://github.com/d3vilh/openvpn-aws) will run on EC2 T2 Nano Instance (1x CPU Core, 512Mb RAM), but it never tested.

# Installation

  1. Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) and Git:
     ```shell 
     sudo apt-get install -y python3-pip
     pip3 install ansible
     sudo apt-get install git
     ```
  2. Clone this repository: 
     ```shell
     git clone https://github.com/d3vilh/openvpn-aws
     ```
  3. Then enter the repository directory: 
     ```shell 
     cd openvpn-aws
     ```
  4. Install requirements: 
     ```shell
     ansible-galaxy collection install -r requirements.yml
     ```
     > If you see `ansible-galaxy: command not found`, you have to relogin and then try again.
  5. Make copies of the configuration files and modify them for your enviroment:
     ```shell
     yes | cp -p example.inventory.ini inventory.ini 
     yes | cp -p example.config.yml config.yml
     ```
  6. Modify `inventory.ini` by replace of IP address with your EC2's Public or Private IPv4 address, or comment that line and uncomment the `connection=local` line if you're running it on the EC2 itself.

  7. Run installation playbook:
     ```shell
     ansible-playbook main.yml
     ```
> **If running locally on the EC2**: You may have error like `Error while fetching server API version`. You have to relogin and then run the playbook again.

## Features

[**OpenVPN**](https://openvpn.net) server with subnets support and **OpenVPN-web-ui** as lightweight web administration interface:

![OpenVPN WEB UI](/images/OpenVPN-UI-Home.png)

<p align="center">
<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_VLANs.png" alt="OpenVPN Subnets" width="600" border="1" />
</p>


# Usage

## OpenVPN 

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

<img src="https://github.com/d3vilh/openvpn-awsblob/master/images/OVPN_ext_serv_ip2.png" alt="Server Address" width="350" border="1" />  <img src="https://github.com/d3vilh/ropenvpn-aws/blob/master/images/OVPN_New_Client.png" alt="Create Certificate" width="350" border="1" />

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

[OpenVPN-AWS'](https://github.com/d3vilh/openvpn-aws/) OpenVPN server uses `10.0.70.0/24` **"Trusted"** subnet for dynamic clients by default and all the clients connected by default will have full access to your Home network, as well as your home Internet.
However you can be desired to share VPN access with your friends and restrict access to your Home network for them, but allow to use Internet connection over your VPN. This type of guest clients needs to live in special **"Guest users"** subnet - `10.0.71.0/24`:

<p align="center">
<img src="https://github.com/d3vilh/openvpn-aws/blob/master/images/OVPN_VLANs.png" alt="OpenVPN Subnets" width="700" border="1" />
</p>

To assign desired subnet policy to the specific client, you have to define static IP address for this client after you generate .OVPN profile.
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

### Alternative, CLI ways to deal with OpenVPN configuration

To generate new .OVPN profile execute following command. Password as second argument is optional:
```shell
sudo docker exec openvpn bash /opt/app/bin/genclient.sh <name> <?password?>
```

You can find you .ovpn file under `/openvpn/clients/<name>.ovpn`, make sure to check and modify the `remote ip-address`, `port` and `protocol`. It also will appear in `"Certificates"` menue of OpenVPN WEB UI.

Revoking of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/rmclient.sh <clientname>
```

Restart of OpenVPN container can be done via the CLI by running following:
```shell
sudo docker-compose restart openvpn
```

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

Build 22.01.2023 by [d3vilh](https://github.com/d3vilh) for small home project.

