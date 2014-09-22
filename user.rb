class User
	def initialize name, host, port
		@name = name
		@host = host
		@port = port
		@heartbeat = Thread.new {
			sleep 5
			Users.logout @host, @port
		}
	end
	
	def heartbeat
		@heartbeat.kill
		@heartbeat = Thread.new {
			sleep 5
			Users.logout @host, @port
		}
	end
end

class Users
	@@users = {}
	
	def self.[] host, port
		@@users["#{host}|#{port}"]
	end
	
	def self.login name, host, port
		@@users["#{host}|#{port}"] = User.new name, host, port
	end
	
	def self.logout host, port
		@@users.delete "#{host}|#{port}"
	end
	
	def self.heartbeat host, port
		@@users["#{host}|#{port}"].heartbeat
	end
end
