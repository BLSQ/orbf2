FROM blsq/hesabu:1.0.257.gce92f2e4

ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD entrypoint.sh