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
			# e agora?
		end
	end
	
	def connect_to host, port
		@connections["#{host}|#{port}"] = TCPSocket.new host, port
	end

	def answer msg, host, port
		send msg, host, port
	end
	
	def send msg, host, port
		@connections["#{host}|#{port}"].print msg
	end
	
	def receive_line host, port
		@connections["#{host}|#{port}"].readline
	end
end

class UDPTransmitter
	def initialize delegate
		@delegate = delegate
		@sockets = {}
	end
	
	def listen_to_port port, limit = nil
		@socket = UDPSocket.new
		@socket.bind nil, port
		loop do
			msg = ""
			sender = nil
			loop do
				char, sender = @socket.recvfrom(1)
				msg += char
				break if char == "\n"
			end
			@delegate.received_line msg, sender
		end
	end
	
	def connect_to host, port
		s = UDPSocket.new
		s.connect host, port
		@sockets["#{host}|#{port}"] = s
	end

	def answer msg, host, port
		@socket.send msg, 0, host, port
	end
	
	def send msg, host, port
		@sockets["#{host}|#{port}"].print msg
	end
	
	def receive_line host, port
		@sockets["#{host}|#{port}"].readline
	end
end
