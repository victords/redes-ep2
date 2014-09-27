class User
	attr_reader :name
	
	def initialize name, addr
		@name = name
		@addr = addr
		@heartbeat = Thread.new {
			sleep 10
			Users.logout @addr
		}
	end
	
	def heartbeat
		@heartbeat.kill
		@heartbeat = Thread.new {
			sleep 10
			Users.logout @addr
		}
	end
end

class Users
	@@users_by_addr = {}
	@@users_by_name = {}
	
	def self.[] key
		return @@users_by_addr[key] if @@users_by_addr[key]
		@@users_by_name[key]
	end
	
	def self.login name, addr
		@@users_by_name[name] = @@users_by_addr[addr.key] = User.new name, addr
	end
	
	def self.logout addr
		u = @@users_by_addr.delete addr.key
		@@users_by_name.delete u.name
	end
end
