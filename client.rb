require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.connect_to host, port
		loop do
			s = gets
			s.chars.each do |c|
				@transmitter.send c, host, port
			end
			puts @transmitter.receive_line host, port
		end
	end
end


