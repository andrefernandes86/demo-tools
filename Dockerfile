FROM ubuntu
RUN apt-get update
RUN apt-get install docker.io -y
COPY demo-tools.sh ./demo-tools.sh
ENTRYPOINT ["sh", "./demo-tools.sh"]
