require_relative 'transmitter'
require_relative 'utils'
include Utils

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
        cmd, user = get_args s
        if cmd == "talkto"
          port = @transmitter.open_port 0
          ans = communicate_with_server("#{s.chomp} #{port}\n")
          code, msg = get_args ans
          if code == 200
            addr = msg.split ':'
            @peer_addr = Address.new addr[0], addr[1].to_i
            @peer_name = user
            @state = :talking
            listen_to_peer
          else
            @transmitter.close_connection Address.new(nil, 0)
            puts "#{user} está ocupado"
          end
        else
          ans = communicate_with_server(s)
          code, msg = get_args ans
          if code == 202
            puts msg
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
      code, msg = get_args ans
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
        cmd, args = get_args msg
        if cmd == "talkto"
          if @state == :talking
            @transmitter.send "405 I'm busy!\n", @server_addr
          else
            info = args.split
            p_addr = Address.new info[1], info[2].to_i
            port = @transmitter.connect_to p_addr
            # puts "port: #{port}, p_addr: #{p_addr.key}"
            @transmitter.send "200 #{port}\n", @server_addr
            @transmitter.send "init\n", p_addr
            @peer_addr = p_addr
            @peer_name = info[0]
            @state = :talking
            puts "iniciei conversa"
            listen_to_peer
          end
        end
      end
    end
  end

  def listen_to_peer
    Thread.new do
      loop do
        msg, addr =  @transmitter.receive :command, @peer_addr
        cmd, args = get_args msg
        if cmd == "msg"
          puts args
        elsif cmd == "init"
          puts "Iniciada conversa com #{@peer_name}"
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
