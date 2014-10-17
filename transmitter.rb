require 'socket'

class Address
	attr_reader :host, :port

	def initialize host, port
		host = "localhost" if host == "127.0.0.1"
		@host = host
		@port = port
	end

	def key
		"#{@host}|#{@port}"
	end

	def == other
		@host == other.host and @port == other.port
	end
end

class TCPTransmitter
	def initialize
		@connections = {}
		@has_command = Queue.new
		@has_message = Queue.new
		@command_addr_queue = []
		@message_addr_queue = []
		@commands_queues = {}
		@messages_queues = {}
		@threads = []
	end

	def open_port port
		server = TCPServer.open(port)
		t = Thread.start(server) do |server|
			loop do
				s = server.accept
				addr = Address.new(s.peeraddr[3], s.peeraddr[1])
        # puts "conexao aceita com #{addr.key}"
				@connections[addr.key] = s
				listen_to_socket addr
			end
		end
		@threads << t
    server.addr[1]
	end

	def connect_to addr, local_port = nil
    @connections[addr.key] = TCPSocket.new addr.host, addr.port, "localhost", local_port
		listen_to_socket addr
  end

	def listen_to_socket addr
		@threads.push(Thread.start(addr) do |addr|
			@commands_queues[addr.key] = Queue.new
			@messages_queues[addr.key] = Queue.new
			conn = @connections[addr.key]
			until conn.closed?
        msg = conn.readline
        # puts "mensagem recebida de #{addr.key}: #{msg}"
				if msg[0].to_i > 0
					@messages_queues[addr.key] << msg
					@message_addr_queue << addr
					@has_message << 0
				else
					@commands_queues[addr.key] << msg
          puts "#{addr.key}: #{@commands_queues[addr.key].size}"
					@command_addr_queue << addr
					@has_command << 0
				end
			end
			puts "saiu..."
		end)
	end

	def close_connection addr
		@connections[addr.key].close
		@connections.delete addr.key
	end

	def send msg, addr
		begin
			@connections[addr.key].print msg
		rescue
			puts "The server has closed the connection!"
			:error
		end
	end

	def receive type = :command, addr = nil
		msg = nil
		queues = type == :command ? @commands_queues : @messages_queues
		addrs = type == :command ? @command_addr_queue : @message_addr_queue
		has = type == :command ? @has_command : @has_message
		if addr
      puts "pop #{addr.key}..."
      msg = queues[addr.key].pop
      puts "foi #{addr.key}"
			has.pop
			addrs.delete_at(addrs.index(addr) || addrs.length)
		else
			has.pop
			addr = addrs.shift
			msg = queues[addr.key].pop
		end
		[msg, addr]
	end

	def close
		@threads.each { |t| t.kill }
		@connections.each_value { |c| c.close }
	end
end

class UDPTransmitter
	def initialize
		@sockets = []
		@connections = {}
		@has_command = Queue.new
		@has_message = Queue.new
		@command_addr_queue = []
		@message_addr_queue = []
		@commands_queues = {}
		@messages_queues = {}
		@threads = []
		@messages = {}
	end

	def open_port port
		s = UDPSocket.new
		@sockets << s
		s.bind nil, port
		addr = Address.new(nil, port)
		@connections[addr.key] = s
		listen_to_socket addr
	end

	def connect_to addr
		s = UDPSocket.new
		s.bind nil, 0
		@sockets << s
		@connections[addr.key] = s
		init_queues_if_nil addr
		listen_to_socket addr
	end

	def listen_to_socket sock_addr
		@threads.push(Thread.start(sock_addr) do |sock_addr|
			s = @connections[sock_addr.key]
			loop do
				msg, addr = read_line s
				init_queues_if_nil addr
				if msg[0].to_i > 0
					@messages_queues[addr.key] << msg
					@message_addr_queue << addr
					@has_message << 0
				else
					@commands_queues[addr.key] << msg
					@command_addr_queue << addr
					@has_command << 0
				end
			end
		end)
	end

	def read_line s
		addr = nil
		loop do
			char, sender = s.recvfrom(1)
			addr = Address.new(sender[3], sender[1])
			@connections[addr.key] = s if @connections[addr.key].nil?
			@messages[addr.key] = "" if @messages[addr.key].nil?
			@messages[addr.key] += char
			break if char == "\n"
		end
		msg = @messages[addr.key]
		@messages[addr.key] = ""
		[msg, addr]
	end

	def close_connection addr
		@connections.delete addr.key
	end

	def send msg, addr
		begin
			s = @connections[addr.key]
			msg.chars.each do |c|
				s.send c, 0, addr.host, addr.port
			end
		rescue Exception => e
			puts e.message
			:error
		end
	end

	def receive type = :command, addr = nil
		msg = nil
		queues = type == :command ? @commands_queues : @messages_queues
		addrs = type == :command ? @command_addr_queue : @message_addr_queue
		has = type == :command ? @has_command : @has_message
		if addr
			init_queues_if_nil addr
			msg = queues[addr.key].pop
			has.pop
			addrs.delete_at(addrs.index(addr) || addrs.length)
		else
			has.pop
			addr = addrs.shift
			init_queues_if_nil addr
			msg = queues[addr.key].pop
		end
		[msg, addr]
	end

	def close
		@threads.each { |t| t.kill }
		@sockets.each { |c| c.close }
	end

	def init_queues_if_nil addr
		@commands_queues[addr.key] = Queue.new if @commands_queues[addr.key].nil?
		@messages_queues[addr.key] = Queue.new if @messages_queues[addr.key].nil?
	end
end
