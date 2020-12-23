##
# Meta-programming hiredis for redis async extension
module Hiredis
  require 'hiredis/connection'
  # Overwrite with ruby implementation to hook IO
  require 'hiredis/ruby/connection'
  require 'hiredis/ruby/reader'
  # Redis Connection
  Connection = Ruby::Connection
  # Redis Result Reader
  Reader = Ruby::Reader

  ##
  # Meta-programming hiredis for redis async extension
  module Ruby
    ##
    # Meta-programming hiredis for redis async extension
    class Connection
      # Do redis query
      # @param [Array] args equal to Hiredis write args
      def query(args)
        data = pre_write(args)
        @sock.write(data)

        while (reply = @reader.gets) == false
          Fiber.scheduler.io_wait(@sock, IO::READABLE, 5)
          @reader.feed @sock.read_nonblock(1024)
        end

        reply
      end

      private
        def pre_write(args)
          command = []
          command << "*#{args.size}"
          args.each do |arg|
            arg = arg.to_s
            command << "$#{string_size arg}"
            command << arg
          end
          data = command.join(COMMAND_DELIMITER) + COMMAND_DELIMITER
          data.force_encoding('binary') if data.respond_to?(:force_encoding)
          data
        end
    end
  end
end

require 'redic'

##
# Meta-programming Redic for redis async extension
class Redic
  # Meta-programming Redic for redis async extension
  class Client
    # Connect redis, yield optional
    def connect
      establish_connection unless connected?
      if block_given?
        # Redic default yield
        # :nocov:
        @semaphore.synchronize do
          yield
        end
        # :nocov:
      end
    end
    
    # Call without thread lock
    # @param [Array] args same params as Redic
    def call(*args)
      @connection.query(*args)
    end
  end

  # Call without thread lock
  # @param [Array] args same params as Redic
  def call(*args)
    @client.connect
    @client.call(args)
  end
end
