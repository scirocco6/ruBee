require './icb_packet'
require 'thread'
require 'readline'

class UserInput < Thread
  def initialize
    super do
      while 1 do
        system "stty raw -echo cbreak"
        if $stdin.wait
          line = ''
          $screen_semaphore.synchronize do
            system "stty #{TERMINAL_STATE}"
            line = Readline.readline('', true)
          end
                   
          unless line.start_with? '/'
            IcbPacket::new(:open, [line]).send($icb_socket)
          else
            input = line.split
            if input.first == '/beep'
              IcbPacket::new(:beep, [input.last]).send($icb_socket)
            elsif line =~ /^\/m\s(.*)/
              IcbPacket::new(:private, [$1]).send($icb_socket)
            elsif line =~ /^\/g\s(.*)/
              IcbPacket::new(:group, [$1]).send($icb_socket)
            elsif line =~ /^\/w\s(.+)/
              IcbPacket::new(:who, [$1]).send($icb_socket)
            elsif line =~ /^\/w/
              IcbPacket::new(:who_global).send($icb_socket)
            elsif line =~ /^\/nop/
              IcbPacket::new(:nop).send($icb_socket)  
            elsif (line =~ /^\/quit/) or (line =~ /^\/q$/) or (line =~ /^\/exit/)
              exit     
            end
          end
        end
      end
    end
  end
end
