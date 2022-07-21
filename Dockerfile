FROM ubuntu
RUN apt-get update
COPY demo-tools.sh ./demo-tools.sh
ENTRYPOINT ["sh", "./demo-tools.sh"]
