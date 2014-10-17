require_relative 'user'
require_relative 'transmitter'

class Server
	def initialize port, transmitter_class
		@port = port
		@transmitter = transmitter_class.new
		@type = transmitter_class.to_s[0..2]
	end

	def start
		@transmitter.open_port @port
		loop do
			msg, addr = @transmitter.receive
			msg = msg.chomp
			cmd = msg.split[0].downcase
			args = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
			process_command cmd, args, addr
		end
	end

	def close
		puts "\nClosing #{@type} server..."
		@transmitter.close
		puts "See ya!"
	end

private

	def process_command cmd, args, addr
		case cmd
		when "login"
			process_login args, addr
		when "logout"
			process_logout addr
		when "htbeat"
			process_heartbeat addr
		when "list"
			process_list addr
		when "talkto"
			process_talkto args, addr
		else
			error 501, "command not recognized.", addr
		end
	end

	def process_login user_name, addr
		if user_name.nil?
			# client deve impedir que isso ocorra
			error 501, "you must provide a user name.", addr
		elsif Users[user_name]
			error 401, "user #{user_name} already logged in.", addr
		else
			Users.login user_name, addr
			answer 201, "Welcome, #{user_name}!", addr
		end
	end

	def process_logout addr
		if Users[addr.key]
			Users.logout addr
			answer 202, "Bye, bye!", addr
			@transmitter.close_connection addr
		else
			# client deve impedir que isso ocorra
			error 402, "user not logged in!", addr
		end
	end

	def process_heartbeat addr
		Users[addr.key].heartbeat
		answer 200, "OK", addr
    # puts "htbeat"
	end

	def process_list addr
		s = ""
		Users.all.each_with_index do |u, i|
			s += "#{i+1}. #{u.name} (since #{u.login_time});"
		end
		answer 200, s, addr
	end

	def process_talkto args, addr
		user_a = Users[addr.key]
		if user_a.nil?
			error 402, "you are not logged in!", addr
      return
    end

    user_b_name, user_a_port = args.split

		if user_b_name.nil?
			error 501, "you must provide a user name.", addr
      return
		end

		user_b = Users[user_b_name]
		if user_b.nil?
			error 404, "user not found.", addr
      return
    end

		@transmitter.send "talkto #{user_a.name} #{addr.host} #{user_a_port}\n", user_b.addr
		msg, user_b_addr = @transmitter.receive :message, user_b.addr
    msg = msg.chomp
    code = msg.split[0].downcase
    arg = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
    arg = "#{user_b_addr.host}:#{arg}" if code.to_i == 200
    answer code, arg, addr
	end

	def answer code, msg, addr
		@transmitter.send "#{code} #{msg}\n", addr
	end

	def error code, msg, addr
		@transmitter.send "#{code} Error: #{msg}\n", addr
	end
end
