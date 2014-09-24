require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.connect_to host, port
		loop do
			@transmitter.send gets, host, port
			puts @transmitter.receive_line host, port
		end
	end
end


