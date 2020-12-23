require 'sequel'
require 'sequel/adapters/postgres'

# Management of Postgres Sockets
POSTGRES_SOCKETS = {}

##
# Midori Extension of sequel postgres through meta programming
class Sequel::Postgres::Adapter
  # Call a sql request asynchronously
  # @param [String] sql sql request
  # @param [Array] args args to send
  # @return [Array] sql query result
  alias_method :execute_query_block, :execute_query

  def execute_query(sql, args)
    if Fiber.scheduler.nil?
      # Block usage
      return execute_query_block(sql, args)
    else
      # Nonblock usage
      return execute_query_nonblock(sql, args)
    end
  end

  def execute_query_nonblock(sql, args)
    @db.log_connection_yield(sql, self, args) do
      if POSTGRES_SOCKETS[self].nil?
        POSTGRES_SOCKETS[self] = IO::open(socket)
      end
      socket_obj = POSTGRES_SOCKETS[self]
      Fiber.scheduler.io_wait(socket_obj, IO::WRITABLE, 5)
      send_query(sql) unless is_busy
      Fiber.scheduler.io_wait(socket_obj, IO::READABLE, 5)
      resolve.call(get_result)
    end
  end
end
