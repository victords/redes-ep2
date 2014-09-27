require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@server_addr = Address.new(host, port)
		@transmitter = transmitter_class.new self
		@transmitter.connect_to @server_addr
		@semaphore = Mutex.new
		heartbeat @server_addr
		loop do
			s = gets
			next if s == "\n"
			send_server s, @server_addr
			puts @transmitter.receive_line @server_addr
		end
	end

	def heartbeat server_addr
		sleep 4
		Thread.new do
			send_server "htbeat", server_addr
			puts @transmitter.receive_line server_addr
			sleep 10
		end
	end

	def send_server msg, server_addr
		@semaphore.synchronize do
			@transmitter.send msg, server_addr
		end
	end
end


