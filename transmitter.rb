require 'socket'

class TCPTransmitter
	def initialize delegate
		@delegate = delegate
		@sockets = {}
	end
	
	def listen_to_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		loop do
			s = server.accept
			puts "aceitou conexão"
			host = s.addr[3]; port = s.addr[1]
			@sockets["#{host}|#{port}"] = s
			@delegate.accepted_connection host, port
			count += 1
			break if count == limit
		end
	end
	
	def connect_to host, port
		@sockets["#{host}|#{port}"] = TCPSocket.new host, port
	end
	
	def send msg, host, port
		@sockets["#{host}|#{port}"].write msg
	end
	
	def receive_line host, port
		socket = @sockets["#{host}|#{port}"]
		msg = socket.readline
		@delegate.received_line msg, socket.addr
	end
	
	def listen_to_socket host, port
		socket = @sockets["#{host}|#{port}"]
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
