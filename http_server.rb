require "socket"

require "socket"
server = TCPServer.new(3000)

while session = server.accept
  request = session.gets
  puts request

  session.print "HTTP/1.1 200\r\n"
  session.print "Content-Type: text/html\r\n"
  session.print "\r\n"
  session.print "hesabu: #{ENV['RELEASE_TAG']}"

  session.close
end
