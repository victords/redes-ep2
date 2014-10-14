require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@server_addr = Address.new(host, port)
		@transmitter = transmitter_class.new
		@transmitter.connect_to @server_addr
		@semaphore = Mutex.new
		
		@logged = false
		until @logged
			print "User: "
			s = gets
			next if s == "\n"
			ans = communicate_with_server("login #{s}")
			code = ans.split[0].to_i
			msg = ans[(ans.index(' ')+1)..-1]
			puts msg
			if code == 201
				@logged = true
				start_heartbeat
			end
		end
		loop do
			s = gets
			next if s == "\n"
			ans = communicate_with_server(s)
			exit if ans.to_i == 202
			puts ans
		end
	end
	
	def start_heartbeat
		Thread.new do
			loop do
				ans = communicate_with_server "htbeat\n"
				if ans.split[0].to_i != 200
					puts "deu merda!"
				end
				sleep 10
			end
		end
	end
	
	def communicate_with_server msg
		@semaphore.synchronize do
			exit if @transmitter.send(msg, @server_addr) == :error
			msg, addr = @transmitter.receive_message @server_addr
			msg
		end
	end
end

