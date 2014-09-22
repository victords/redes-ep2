require 'socket'

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

class Client
	def initialize host, port, mode
		if mode == "udp"
			s = UDPSocket.new
			s.connect host, port
			until s.closed?
				s.print gets
				msg, sender = s.recvfrom(30)
				puts msg
				s.close if msg.chomp == "Bye!"
			end
		else
			s = TCPSocket.new host, port
			until s.closed?
				s.print gets
				puts s.readline
				if s.eof?; s.close
				else; s.readline; end
			end
		end
	end
end

client = Client.new host, port, mode
