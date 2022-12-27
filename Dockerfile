FROM blsq/hesabu:1.0.257.gce92f2e4

ADD entrypoint.sh
EXPOSE 3000
CMD entrypoint.sh