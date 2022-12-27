FROM blsq/hesabu:1.0.268.g5d1e8efb

ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD ./entrypoint.sh