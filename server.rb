require 'socket'

if ARGV.length < 1
	puts "Usage: server.rb PORT"
	puts "  PORT is the number of the port where the server will listen for connections."
	exit 0
end

port = ARGV.shift.to_i

class Server
	def initialize port
		# Inicializando UDP
		Thread.start do
			server = UDPSocket.new
			server.bind nil, port
			loop {
				msg, sender = server.recvfrom(10)
				process msg, sender
			}
		end
		
		# Inicializando TCP
		server = TCPServer.open(port)
		loop {
			Thread.start(server.accept) do |client|
				puts "aceitou conexão"
				while
					msg = client.readline
					process msg, client.addr
				end
			end
		}
	end
	
	def process msg, sender
		msg = msg.chomp
		cmd = msg.split[0].downcase
		args = msg[(msg.index(' ')+1)..-1]
		
	end
	
	def 
end

server = Server.new port
