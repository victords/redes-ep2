require 'socket'

class TCPTransmitter
	def initialize delegate
		@delegate = delegate
		@connections = {}
	end
	
	def listen_to_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		loop do
			s = server.accept
			puts "Nova Conexão"
			host = s.addr[3]; port = s.addr[1]
			@connections["#{host}|#{port}"] = s
			@delegate.accepted_connection host, port
			count += 1
			break if count == limit
		end
	end
	
	def connect_to host, port
		@connections["#{host}|#{port}"] = TCPSocket.new host, port
	end
	
	def send msg, host, port
		@connections["#{host}|#{port}"].write msg
	end
	
	def receive_line host, port
		socket = @connections["#{host}|#{port}"]
		socket.readline
	end
	
	def listen_to_socket host, port
		socket = @connections["#{host}|#{port}"]
		loop do
			msg = socket.readline
			@delegate.received_line msg, socket.addr
		end
	end
end

#class UDPTransmitter
#	def initialize
#	end
#	
#	def receive_line
#	end
#	
#	def receive bytes
#	end
#	
#	def send msg
#	end
#end
