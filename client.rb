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
        cmd = s.split[0]
        if cmd == "talkto"
          port = 60000 # ver como obter porta vaga
          ans = communicate_with_server("#{s.chomp} #{port}\n")
          code = ans.to_i
          msg = ans[(ans.index(' ')+1)..-1]
          if code == 200
            addr = msg.split ':'
            @peer_addr = Address.new addr[0], addr[1].to_i
            # puts "peer_addr: #{@peer_addr.key}"
            @transmitter.connect_to @peer_addr, port
            @transmitter.send "init\n", @peer_addr
            @state = :talking
            puts "iniciei conversa"
          end
        else
          ans = communicate_with_server(s)
          code = ans.to_i
          msg = ans[(ans.index(' ')+1)..-1]
          if code == 202
            puts ans[(ans.index(' ')+1)..-1]
            exit
          elsif code >= 400
            puts msg
          elsif cmd == "list"
            puts msg.split ';'
          end
        end
      elsif @state == :talking
        @transmitter.send "msg #{s}", @peer_addr
      end
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
          if @state == :talking
            @transmitter.send "405 I'm busy!\n", @server_addr
          else
            port = @transmitter.open_port 0
            p_addr = Address.new args.split[0], args.split[1].to_i
            # puts "port: #{port}, p_addr: #{p_addr.key}"
            @transmitter.send "200 #{port}\n", @server_addr
            msg1, addr1 = @transmitter.receive :command, p_addr
            puts "msg1: #{msg1}"
            if msg1.chomp == "init"
              @peer_addr = p_addr
              @state = :talking
              puts "iniciei conversa"
            end
          end
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
			ans, addr = @transmitter.receive :message, @server_addr
			ans
		end
  end
end
