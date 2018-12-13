
ELK-Builder

Simple bash script to install Elasticsearch, Logstash, and Kibana all in one box.

Note: This build should not be for production deployments requiring high I/O. This is a simplistic build for anyone needing debugging or quick log review.

Default username/password = kibana;password This can be changed in the user variable section in the beginning of the script. Note: Kibana (without xpack) does not have authentication out of the box, this is why I used NGINX with basic authentication over TLS/SSL.

Logstash is listening on port 1514 (TCP and UDP) using the syslog protocol.

System Requirements: Ubuntu Server 14.04 (Trusty) - At least 4gb RAM - At least 10gb Storage Available -
