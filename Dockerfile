FROM blsq/hesabu:1.0.286.gbbb2f59c

ADD ./bin/eb/every_ten.sh /bin/eb/every_ten.sh
ADD ./bin/eb/every_day.sh /bin/eb/every_day.sh
ADD http_server.rb http_server.rb
ADD entrypoint.sh entrypoint.sh

EXPOSE 3000

CMD ./entrypoint.sh