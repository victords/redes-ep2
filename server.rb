require 'socket'

server = TCPServer.open(ARGV[0])
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
