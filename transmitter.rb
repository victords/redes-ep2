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
	
	def self.from_key key
		k = key.split('|')
		Address.new k[0], k[1].to_i
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
		Thread.start(server) do |server|
			loop do
				s = server.accept
				puts "Nova Conexão"
				addr = Address.new(s.peeraddr[3], s.peeraddr[1])
				puts addr.key
				@connections[addr.key] = s
				Thread.start(addr) do |addr|
					puts "iniciando #{addr.port}"
					conn = @connections[addr.key]
					until conn.closed?
						puts "aguardando linha #{addr.port}"
						msg = conn.readline
						puts "linha lida #{addr.port}"
						@messages.push([addr.key, msg])
						puts "linha adicionada #{addr.port}"
					end
					puts "finalizando conexão"
				end
			end
		end
		loop do
			unless @messages.empty?
				key, value = @messages.shift
				puts key
				@delegate.received_line value, Address.from_key(key)
			end
		end
	end
	
	def connect_to addr
		@connections[addr.key] = TCPSocket.new addr.host, addr.port
	end
	
	def answer msg, addr
		puts "respondendo #{addr.port}"
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
