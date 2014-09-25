require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		@transmitter = transmitter_class.new self
		@transmitter.connect_to host, port
		addr = Address.new(host, port)
		loop do
			s = gets
			next if s == "\n"
			s.chars.each do |c|
				@transmitter.send c, addr
			end
			puts @transmitter.receive_line addr
		end
	end
end


