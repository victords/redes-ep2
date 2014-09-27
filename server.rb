require_relative 'user'
require_relative 'transmitter'

class Server
	def initialize port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.listen_to_port port
	end
	
	def received_line msg, addr
		puts "Mensagem recebida: #{msg}"
		msg = msg.chomp
		cmd = msg.split[0].downcase
		args = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
		process_command cmd, args, addr
	end
	
	def process_command cmd, args, addr
		case cmd
		when "login"
			process_login args, addr
		when "logout"
			process_logout addr
		when "htbeat"
			process_heartbeat addr
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
			@transmitter.answer 202, "Bye, bye!", addr
			@transmitter.close_connection addr
		else
			# client deve impedir que isso ocorra
			error 402, "user not logged in!", addr
		end
	end
	
	def process_heartbeat addr
		Users[addr.key].heartbeat
		answer 200, "OK", addr
	end
	
	def answer code, msg, addr
		@transmitter.answer "#{code} #{msg}\n", addr
	end
	
	def error code, msg, addr
		@transmitter.answer "#{code} Error: #{msg}\n", addr
	end
end
