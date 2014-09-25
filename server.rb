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
			@transmitter.answer "login\n", addr
		when "logout"
			@transmitter.answer "logout\n", addr
		else
			@transmitter.answer "#{cmd}???\n", addr
		end
	end
end
