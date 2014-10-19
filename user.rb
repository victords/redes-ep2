require_relative 'utils'
include Constants

class User
	attr_reader :name, :addr, :login_time

	def initialize name, addr
		@name = name
		@addr = addr
		@login_time = Time.now.strftime("%d/%m/%Y %H:%M")
		@heartbeat = Thread.new {
			sleep HEARTBEAT_TOLERANCE
			Users.logout @addr
		}
	end

	def heartbeat
		@heartbeat.kill
		@heartbeat = Thread.new {
			sleep HEARTBEAT_TOLERANCE
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

	def self.all
		@@users_by_name.values.sort_by { |u| u.name }
	end
end
