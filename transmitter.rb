require 'socket'

Address = Struct.new :host, :port do
	def key
		"#{@host}|#{@port}"
	end

	def self.from_key key
		k = key.split('|')
		Address.new k[0].to_i, k[1].to_i
	end
end

class TCPTransmitter
	def initialize delegate
		@delegate = delegate
		@connections = {}
		@messages = {}
	end
	
	def listen_to_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		Thread.start(server) do |server|
			loop do
				s = server.accept
				puts "Nova Conexão"
				host = s.addr[3]; port = s.addr[1]
				
			end
		end
		loop do
			unless @messages.empty?
				key, value = @messages.shift
				@delegate.received_line value, Address.from_key(key)
			end
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
	
	def connect_to host, port
		s = UDPSocket.new
		s.connect host, port
		@sockets[Address.new(host, port).key] = s
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
