require_relative 'client'
require_relative 'transmitter'

if ARGV.length < 3
	puts "Usage: client.rb HOST PORT MODE"
	puts "  HOST is the hostname or address of the server."
	puts "  PORT is the number of the port where the server is listening for connections."
	puts "  MODE must be either 'tcp' or 'udp'."
	exit 0
end

host = ARGV.shift
port = ARGV.shift.to_i
mode = ARGV.shift.downcase

client = Client.new host, port, mode == 'tcp' ? TCPTransmitter : UDPTransmitter
