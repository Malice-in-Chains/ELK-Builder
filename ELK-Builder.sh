#!/bin/bash
# ELK-Builder v1.0
# Builds Elasticsearch, Logstash, and Kibana all-in-one appliance on Ubuntu Server 14.04 (Trusty)
# Created by MaliceInChains

#-------------- User set variables --------------#
user=kibana
password=password
host_name=ELKv5-Stack
#------------------------------------------------#

# Set host IP variable
host_ip=$(ifconfig eth0 |grep "inet addr" |awk '{print$2}' |awk -F "addr:" '{print$2}')

# Change hostname
sudo hostname $host_name;cat /etc/hosts |sed -e "s/127.0.0.1 localhost/127.0.0.1 $host_name/g" > /etc/hostss; mv /etc/hostss /etc/hosts;echo $host_name > /etc/hostname

# Update system
sudo apt-get update

# Add Java v8 Repository to APT
sudo add-apt-repository -y ppa:webupd8team/java;sudo apt-get update

# Agree to Java License (prevent manual agreement)
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true |sudo debconf-set-selections

# Update system and install Java8
sudo apt-get -y install oracle-java8-installer

# Install apt-transport-https 
sudo apt-get -y install apt-transport-https

# Download and install
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

# Add package to sources.list, update system, and install elasticsearch
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

# Update System
sudo apt-get update

#Install Elasticsearch
sudo apt-get -y install elasticsearch

#Install logstash
sudo apt-get -y install logstash

#Install Kibana
sudo apt-get -y install kibana

# Install Nginx
sudo apt-get -y install nginx

# Generate a temporary self signed certificate for web nginx web server
sudo mkdir /etc/ssl/nginx/;sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/private.key -out /etc/ssl/nginx/certificate.crt -subj "/C=US/ST=California/L=LA/O=HACKS/OU=Elasticsearch/CN=Kibana"

# Create reverse proxy from 443 to localhost 5601 and encrpyt client traffic and provide basic auth
cat > /etc/nginx/sites-available/default << EOL
server {
    listen 443;

    ssl    on;
    ssl_certificate    /etc/ssl/nginx/certificate.crt;
    ssl_certificate_key    /etc/ssl/nginx/private.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

#    server_name example.com;
#    auth_basic "Restricted Access";
#    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Set default admin username and password for basic authentication
# htpasswd -b -c /etc/nginx/htpassword.users $user $password

# Set server.host in kibana.yml
echo "server.host: localhost" > /etc/kibana/kibana.yml

# Create a syslog listener on port 1514
cat > /etc/logstash/conf.d/000-syslog.conf << EOL
input {
   syslog {
   host => "$host_ip"
   port => 1514
   }
}
EOL

# Create logstash output to elasticsearch database
cat > /etc/logstash/conf.d/200-elasticsearch.conf << EOL
output {
   elasticsearch {
   index => "logstash-%{+YYYY.MM.dd}"
   }
}
EOL

# Start all services
service elasticsearch restart
service logstash restart
service kibana restart
service nginx restart
