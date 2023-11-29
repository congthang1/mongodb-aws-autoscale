FROM mongo:5.0.16
RUN apt-get update && apt-get install -y curl && apt-get install -y openssh-client && apt install -y iproute2
COPY ssh-keyname.pem /sshdb-key.pem
RUN chmod 400 /sshdb-key.pem
COPY keyfile.pem /keyfile.pem
COPY custominit.sh /docker-entrypoint-initdb.d/
RUN chmod a+x /docker-entrypoint-initdb.d/custominit.sh
COPY custom-entrypoint.sh /usr/local/bin/
COPY reconfigrs.sh /usr/local/bin/
RUN chown mongodb:mongodb /keyfile.pem
RUN chmod 400 /keyfile.pem
RUN chmod a+x /usr/local/bin/custom-entrypoint.sh
RUN chmod a+x /usr/local/bin/reconfigrs.sh
ENTRYPOINT [ "custom-entrypoint.sh" ]
EXPOSE 27017
CMD ["mongod"]