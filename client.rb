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
	end

  def start
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
            puts "#{msg}"
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
        print "=> "
      elsif @state == :talking
        process_talk s
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
        @user_name = s.chomp
				start_heartbeat
        print "=> "
			end
		end
  end

  def listen_to_server
    @server_thread = Thread.new do
      loop do
        msg, addr = @transmitter.receive :command, @server_addr
        cmd, args = get_args msg
        if cmd == "talkto"
          if @state == :talking
            @transmitter.send "405 #{@user_name} is busy!\n", @server_addr
          else
            info = args.split
            info[1] = @server_addr.host if info[1] == "localhost"
            p_addr = Address.new info[1], info[2].to_i
            port = @transmitter.connect_to p_addr
            @transmitter.send "200 #{port}\n", @server_addr
            @transmitter.send "init\n", p_addr
            @peer_addr = p_addr
            @peer_name = info[0]
            @state = :talking
            puts "[Started talking to #{@peer_name}]"
            listen_to_peer
          end
        end
      end
    end
  end

  def listen_to_peer
    @talk_thread = Thread.new do
      loop do
        msg, addr =  @transmitter.receive :command, @peer_addr
        cmd, args = get_args msg
        if cmd == "msg"
          puts "- #{@peer_name}: #{args}"
        elsif cmd == "init"
          puts "[Started talking to #{@peer_name}]"
        elsif cmd == "shutup"
          shutup
        elsif cmd == "file"
          file_name = args.split[0]
          file_size = args.split[1].to_i
          port = @transmitter.open_file_port file_size
          @transmitter.send "200 #{port}\n", @peer_addr
          @file_thread = Thread.new do
            file = @transmitter.receive_file
            f = File.open(file_name, 'wb')
            f.write(file)
            f.close
            puts "[File '#{file_name}' successfully received]"
          end
        end
      end
    end
  end

  def process_talk s
    if s.index("/") == 0
      cmd, args = get_args s
      if cmd == "/shutup"
        @transmitter.send "shutup\n", @peer_addr
        shutup
      elsif cmd == "/file"
        unless File.exist? args
          puts "[File '#{args}' not found]"
          return
        end
        @transmitter.send "file #{File.basename(args)} #{File.size(args)}\n", @peer_addr
        msg, addr = @transmitter.receive :message, @peer_addr
        code, text = get_args msg
        if code == 200
          @file_thread = Thread.new do
            addr = Address.new @peer_addr.host, text.to_i
            @transmitter.connect_to_file addr
            @transmitter.send_file args, addr
            puts "[File '#{args}' successfully sent]"
          end
        end
      else
        puts "[Command not recognized]"
      end
    else
      @transmitter.send "msg #{s}", @peer_addr
    end
  end

  def shutup
    @transmitter.close_connection @peer_addr
    @state = :logged
    puts "[Ended conversation with #{@peer_name}]"
    print "=> "
    @talk_thread.kill
  end

	def start_heartbeat
		@ht_thread = Thread.new do
			loop do
				ans = communicate_with_server "htbeat\n"
				if ans.split[0].to_i != 200
					puts "Shit happened!"
				end
				sleep Constants::HEARTBEAT_INTERVAL
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

  def close
    @transmitter.send "shutup\n", @peer_addr if @state == :talking
    @transmitter.send "logout\n", @server_addr
    @ht_thread.kill unless @ht_thread.nil?
    @file_thread.kill unless @file_thread.nil?
    @server_thread.kill unless @server_thread.nil?
    @talk_thread.kill unless @talk_thread.nil?
    @transmitter.close unless @transmitter.nil?
    puts "\nSee you soon!"
  end
end
