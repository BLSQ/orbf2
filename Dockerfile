FROM blsq/hesabu:1.0.279.g7607539d 

ADD ./bin/eb/every_ten.sh /bin/eb/every_ten.sh
ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD ./entrypoint.sh