require "socket"

require "socket"
server = TCPServer.new(3000)

while session = server.accept
  request = session.gets
  puts request

  session.print "HTTP/1.1 200\r\n"
  session.print "Content-Type: text/plain\r\n"
  session.print "\r\n"
  session.print [
    "APPLICATION: hesabu",
    "RELEASE_TAG: #{ENV['RELEASE_TAG']}",
    "RELEASE_TIME: #{ENV['RELEASE_TIME']}"
  ].join("\n")

  session.close
end
