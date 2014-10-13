require 'socket'

class Address
	attr_reader :host, :port
	
	def initialize host, port
		@host = host
		@port = port
	end
	
	def key
		"#{@host}|#{@port}"
	end
end

class TCPTransmitter
	def initialize delegate
		@connections = {}
		@commands_queues = {}
		@messages_queues = {}
	end
	
	def open_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		t = Thread.start(server) do |server|
			loop do
				s = server.accept
				addr = Address.new(s.peeraddr[3], s.peeraddr[1])
				puts addr.key
				@connections[addr.key] = s
				listen_to_socket addr
			end
		end
	end

	def listen_to_socket addr
		Thread.start(addr) do |addr|
			@commands_queues[add.key] = Queue.new
			@commands_queues[add.key] = Queue.new
			conn = @connections[addr.key]
			until conn.closed?
				msg = conn.readline
				if msg[0].is_a? Numeric
					@@commands_queues[add.key] << msg
				else
					@commands_queues[add.key] << msg
				end
			end
			puts "saiu..."
		end
	end
	
	def connect_to addr
		@connections[addr.key] = TCPSocket.new addr.host, addr.port
		listen_to_socket addr
	end
	
	def close_connection addr
		@connections[addr.key].close
		@connections.delete addr.key
	end
	
	def answer msg, addr
		send msg, addr
	end
	
	def send msg, addr
		@connections[addr.key].print msg
	end
	
	def receive_command addr
		if addr
			
		else
			
		end
		@connections[addr.key].readline
	end


end

class UDPTransmitter
	def initialize delegate
		@sockets = {}
		@commands_queue = Queue.new
		@messages_queue = Queue.new
	end
	
	def listen_to_port port, limit = nil
		@socket = UDPSocket.new
		@socket.bind nil, port
		messages = {}
		loop do
			addr = nil
			loop do
				char, sender = @socket.recvfrom(1)
				addr = Address.new(sender[3], sender[1])
				messages[addr.key] = "" if messages[addr.key].nil?
				messages[addr.key] += char
				break if char == "\n"
			end
			@delegate.received_line messages[addr.key], addr
			messages[addr.key] = ""
		end
	end
	
	def connect_to addr
		s = UDPSocket.new
		s.connect addr.host, addr.port
		@sockets[addr.key] = s
	end
	
	def close_connection addr
		
	end

	def answer msg, addr
		@socket.send msg, 0, addr.host, addr.port
	end
	
	def send msg, addr
		msg.chars.each do |c|
			@sockets[addr.key].print c
		end
	end
	
	def receive_line addr
		@sockets[addr.key].readline
	end
end
