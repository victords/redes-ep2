require_relative 'user'
require_relative 'transmitter'

class Server
	def initialize port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.listen_to_port port
	end
	
	def received_line msg, sender
		puts "Mensagem recebida: #{msg}"
		msg = msg.chomp
		cmd = msg.split[0].downcase
		args = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
		process_command cmd, args, sender
	end

	def process_command cmd, args, sender
		host = sender[3]; port = sender[1]
		case cmd
		when "login"
			@transmitter.answer "login\n", host, port
		when "logout"
			@transmitter.answer "logout\n", host, port
		else
			@transmitter.answer "#{cmd}???\n", host, port
		end
	end
end
