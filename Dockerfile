FROM blsq/hesabu:1.0.323.g6b14240d

ADD ./bin/eb/every_ten.sh /bin/eb/every_ten.sh
ADD ./bin/eb/every_day.sh /bin/eb/every_day.sh
ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD ./entrypoint.sh