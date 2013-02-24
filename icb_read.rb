require './icb_packet'
require "io/wait"
require 'thread'

class IcbRead < Thread
  def initialize
    super do
      while 1 do
        packet_size = $icb_socket.read(1) # read blocks until correct # of chars received
        packet      = $icb_socket.read(packet_size[0].ord) # recv returns with as many characters as are ready
        message     = IcbPacket.decode(packet)
        
        $screen_semaphore.synchronize do
          puts(message)
        end
      end
    end
  end
end
  