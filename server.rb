require_relative 'user'
require_relative 'transmitter'

class Server
	def initialize port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.listen_to_port port
	end

	def accepted_connection host, port
		Thread.start(host, port) do |host, port|
			@transmitter.listen_to_socket host, port
		end
	end
	
	def received_line msg, sender
		puts "Mensagem recebida: #{msg}"
		msg = msg.chomp
		cmd = msg
		args = nil
		index = msg.index(' ')
		if index
			cmd = msg[0..index].downcase
			args = msg[(index+1)..-1]
		end
		process_command cmd, args, sender
	end

	def process_command cmd, args, sender
		host = sender[3]; port = sender[1]
		case cmd
		when "login"
			@transmitter.send "login\n", host, port
		when "logout"
			@transmitter.send "logout\n", host, port
		else
			@transmitter.send "#{cmd}???\n", host, port
		end
	end
end
