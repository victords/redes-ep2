require_relative 'user'
require_relative 'transmitter'

class Server
	def initialize port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.listen_to_port port
	end
	
	def received msg, sender
		puts "Mensagem recebida: #{msg}"
#		msg = msg.chomp
#		cmd = msg.split[0].downcase
#		args = msg[(msg.index(' ')+1)..-1]
	end
end
