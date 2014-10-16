require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@server_addr = Address.new(host, port)
		@transmitter = transmitter_class.new
		@transmitter.connect_to @server_addr
		@semaphore = Mutex.new
    @state = :not_logged
		
		login

    listen_to_server

		loop do
			s = gets
			next if s == "\n"
      if @state == :logged
        ans = communicate_with_server(s)
        exit if ans.to_i == 202
      elsif @state == :talking

      end
			puts ans
		end
	end

	def login
		until @state == :logged
			print "User: "
			s = gets
			next if s == "\n"
			ans = communicate_with_server("login #{s}")
			code = ans.split[0].to_i
			msg = ans[(ans.index(' ')+1)..-1]
			puts msg
			if code == 201
				@state = :logged
				start_heartbeat
			end
		end
  end

  def listen_to_server
    Thread.new do
      loop do
        msg, addr = @transmitter.receive :command, @server_addr
        msg = msg.chomp
        cmd = msg.split[0].downcase
        args = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
        if cmd == "talkto"
          #check state
          port = @transmitter.open_port 0
          @transmitter.send "200 #{port}", @server_addr
          # @transmitter.recieve :command, addr_q_eu_n_sei
        end
      end
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
			msg, addr = @transmitter.receive :message, @server_addr
			msg
		end
	end
end
