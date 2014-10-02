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
		@delegate = delegate
		@connections = {}
	end
	
	def listen_to_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		t = Thread.start(server) do |server|
			loop do
				s = server.accept
				addr = Address.new(s.peeraddr[3], s.peeraddr[1])
				puts addr.key
				@connections[addr.key] = s
				Thread.start(addr) do |addr|
					conn = @connections[addr.key]
					until conn.closed?
						msg = conn.readline
						@delegate.received_line msg, addr
					end
					puts "saiu..."
				end
			end
		end
		t.join
	end
	
	def connect_to addr
		@connections[addr.key] = TCPSocket.new addr.host, addr.port
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
	
	def receive_line addr
		@connections[addr.key].readline
	end
	
	def close
		@connections.each { |c| c.close }
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
	
	def close
		
	end
end
