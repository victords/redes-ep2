require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.connect_to host, port
		loop do
			@transmitter.send gets
		end
	end
	
	def received msg, sender
		
	end
end


