require 'socket'

s = TCPSocket.new ARGV.shift, ARGV.shift.to_i
until s.closed?
	s.print gets
	puts s.readline
	if s.eof?; s.close
	else; s.readline; end
end
