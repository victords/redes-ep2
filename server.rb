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
		else
			error "command not recognized.", addr
		end
	end
	
	def process_login user_name, addr
		if user_name.nil?
			# client deve impedir que isso ocorra
			error "you must provide a user name.", addr
		elsif Users[user_name]
			error "user #{user_name} already logged in.", addr
		else
			Users.login user_name, addr
			@transmitter.answer "Welcome, #{user_name}!\n", addr
		end
	end
	
	def process_logout addr
		if Users[addr.key]
			Users.logout addr
			@transmitter.answer "Bye, bye!\n", addr
		else
			# client deve impedir que isso ocorra
			error "user not logged in!", addr
		end
	end
	
	def error msg, addr
		@transmitter.answer "Error: #{msg}\n", addr
	end
end
