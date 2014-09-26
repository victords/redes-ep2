require_relative 'transmitter'

class Client
	def initialize host, port, transmitter_class
		addr = Address.new(host, port)
		@transmitter = transmitter_class.new self
		@transmitter.connect_to addr
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


