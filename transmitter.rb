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
		@messages = []
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
						if @messages.empty?
							@delegate.received_line msg, addr
						else
							p_msg, p_addr = @messages.shift
							@delegate.received_line p_msg, p_addr
							@messages.push([msg, addr])
						end
					end
				end
			end
		end
		t.join
	end
	
	def connect_to addr
		@connections[addr.key] = TCPSocket.new addr.host, addr.port
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

	def answer msg, addr
		@socket.send msg, 0, addr.host, addr.port
	end
	
	def send msg, addr
		@sockets[addr.key].print msg
	end
	
	def receive_line addr
		@sockets[addr.key].readline
	end
end
