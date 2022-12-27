FROM blsq/hesabu:1.0.263.g00b87b35

ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD ./entrypoint.sh