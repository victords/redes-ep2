class Address
  attr_reader :host, :port

  def initialize host, port
    host = "localhost" if host == "127.0.0.1"
    @host = host
    @port = port
  end

  def key
    "#{@host}|#{@port}"
  end

  def == other
    @host == other.host and @port == other.port
  end
end

module Utils
  def get_args msg
    msg = msg.chomp
    cmd = msg.split[0].downcase
    args = msg[(msg.index(' ')+1)..-1] if msg.index(' ')
    [cmd.to_i > 0 ? cmd.to_i : cmd, args]
  end
end