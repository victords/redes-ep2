require_relative 'server'
require_relative 'transmitter'

if ARGV.length < 1
	puts "Usage: server.rb PORT"
	puts "  PORT is the number of the port where the server will listen for connections."
	exit 0
end

port = ARGV.shift.to_i

if fork
	udp_server = Server.new port, UDPTransmitter
	trap("INT") do
		udp_server.close
	end
else
	tcp_server = Server.new port, TCPTransmitter
	trap("INT") do
		tcp_server.close
	end
end

