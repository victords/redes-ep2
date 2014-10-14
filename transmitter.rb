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
	def initialize
		@connections = {}
		@has_command = Queue.new
		@has_message = Queue.new
		@commands_queues = {}
		@messages_queues = {}
		@threads = []
	end
	
	def open_port port, limit = nil
		server = TCPServer.open(port)
		count = 0
		t = Thread.start(server) do |server|
			loop do
				s = server.accept
				addr = Address.new(s.peeraddr[3], s.peeraddr[1])
				@connections[addr.key] = s
				listen_to_socket addr
			end
		end
		@threads << t
	end

	def listen_to_socket addr
		@threads.push(Thread.start(addr) do |addr|
			@commands_queues[addr.key] = Queue.new
			@messages_queues[addr.key] = Queue.new
			conn = @connections[addr.key]
			until conn.closed?
				msg = conn.readline
				if msg[0].is_a? Numeric
					@messages_queues[addr.key] << msg
					@has_message << addr
				else
					@commands_queues[addr.key] << msg
					@has_command << addr
				end
			end
			puts "saiu..."
		end)
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
		begin
			@connections[addr.key].print msg
		rescue
			puts "The server has closed the connection!"
			:error
		end
	end
	
	def receive_command addr = nil
		puts "aqui"
		addr = @has_command.pop if addr.nil?
		puts @commands_queues.size
		[@commands_queues[addr.key].pop, addr]
	end

	def receive_message addr
		addr = @has_message.pop if addr.nil?
		[@messages_queues[addr.key].pop, addr]
	end
	
	def close
		@threads.each { |t| t.kill }
		@connections.each_value { |c| c.close }
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
		begin
			msg.chars.each do |c|
				@sockets[addr.key].print c
			end
		rescue
			puts "The server has closed the connection!"
			:error
		end
	end
	
	def receive_line addr
		@sockets[addr.key].readline
	end
	
	def close
		
	end
end
