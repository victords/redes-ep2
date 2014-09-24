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
	
	def receive_all
		Thread.start(host, port) do |host, port|
			socket = @connections["#{host}|#{port}"]
			loop do
				msg = socket.readline
				@delegate.received_line msg, socket.addr
			end
		end
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
			puts "1"
			msg = ""
			loop do 
				puts "2"
				char, sender = @socket.recvfrom(1)
				puts "3"
				msg += char
			  break if char == "\n"
			end 
			puts "4"
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
