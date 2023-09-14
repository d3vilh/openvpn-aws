# Start from Alpine base image
FROM amd64/alpine
LABEL maintainer="Mr.Philipp <d3vilh@github.com>"
LABEL version="0.2"

# Copy all files in the current directory to the /opt/app directory in the container
COPY . /opt/app
# Set the working directory to /opt/app
WORKDIR /opt/app

#RUN apk --no-cache --no-progress upgrade && apk --no-cache --no-progress add bash bind-tools curl wget ip6tables iptables openvpn easy-rsa
RUN apk --no-cache --no-progress upgrade && apk --no-cache --no-progress add bash bind-tools curl ip6tables iptables openvpn easy-rsa

#Install Latest RasyRSA Version
RUN chmod 755 /usr/share/easy-rsa/*

# Add the openssl-easyrsa.cnf file to the easy-rsa directory
ADD openssl-easyrsa.cnf /opt/app/easy-rsa/

# Make all files in the bin directory executable
RUN chmod +x bin/*; chmod +x docker-entrypoint.sh

# Expose the OpenVPN port (1194/udp)
EXPOSE 1194/udp

# Set the entrypoint to the docker-entrypoint.sh script, passing in the following arguments:
# $REQ_COUNTRY $REQ_PROVINCE $REQ_CITY $REQ_ORG $REQ_OU $REQ_CN
ENTRYPOINT ./docker-entrypoint.sh 
#\
#                "$REQ_COUNTRY" \
#                "$REQ_PROVINCE" \
#                "$REQ_CITY" \
#                "$REQ_ORG" \
#                "$REQ_OU" \
#                "$REQ_CN"