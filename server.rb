require 'socket'

if ARGV.length < 1
	puts "Usage: server.rb PORT"
	puts "  PORT is the number of the port where the server will listen for connections."
	exit 0
end

port = ARGV.shift.to_i

# Inicializando UDP
Thread.start do
	server = UDPSocket.new
	server.bind nil, port
	loop {
		msg, sender = server.recvfrom(10)
		if msg.chomp == "exit"
			server.send "Bye!\n", 0, sender[3], sender[1]
		else
			server.send "You typed: #{msg}", 0, sender[3], sender[1]
		end
	}
end

# Inicializando TCP
server = TCPServer.open(port)
loop {
	Thread.start(server.accept) do |client|
		puts "aceitou conexão"
		while (c = client.readline.chomp) != "exit"
			puts "leu"
			client.puts "You typed: #{c}"
			puts "respondeu"
			client.puts
		end
		client.puts "Bye!"
		client.close
	end
}
