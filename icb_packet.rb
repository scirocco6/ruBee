class IcbPacket
  require 'socket'
  
  public
    def self.icb_socket
      address = "default.icb.net"
      port = "7326"
      
      return(TCPSocket.new(address, port))
    end
    
    def self.get_packet(socket)
      return '' unless socket
      
      packet_size = socket.read(1) # read blocks until correct # of chars received
      return(socket.read(packet_size[0].ord)) # recv returns with as many characters as are ready
    end
    
    def self.decode(packet)
      case packet[0,1]          
        when 'b' # open message
          (from, text) = packet.split 1.chr
          return "<#{from[1, from.length]}> #{text}"
          
        when 'c' # personal message
          (from, text) = packet.split 1.chr
          return "<*#{from[1, from.length]}*> #{text}"
        
        when 'd' # status message
          (category, text) = packet.split 1.chr
          return "[=#{category[1, category.length]}=] #{text}"        
          
        when 'e' # error message
          return "[=Server Error=] #{packet[1, packet.length]}"
          
        when 'f' # important message
          (category, text) = packet.split 1.chr
          return "[!#{category[1, category.length]}!] #{text}"
          
        when 'g' # exit
          exit 0
          
        when 'i' # command output 
          case packet[0,3]
            when 'ico'
               return "#{packet[3, packet.length]}"
            when 'iec'
              return "#{packet[3, packet.length]}"
            when 'iwl' # item in a who listing
                return "#{packet[3, packet.length]}"
          end
          
        when 'k' # beep
          return "[=Beep!=] #{packet[1, packet.length]} sent you a beep!"
        
        when 'l' # ping
          return "[=Server=] ping #{packet[1, packet.length]}" 
           
        when 'm' # ping
          return "[=Server=] pong #{packet[1, packet.length]}"
          
        when 'n' # NOP packet
          return "[=Server=] NOP!!@"
          
        else
          return "Unknown packet of type '#{packet[0,1]}'\n#{packet}"
      end
    end

    def initialize(type, paramaters = [])
      case type
        when :beep
#          @type = 'k' # default.icb.net doesn't handle beep packets use command packet beep instead
          @type = 'h'
          paramaters.unshift('beep')
          
        when :login
          @type = 'a'
        
        when :open
          @type = 'b'
          
        when :private
          @type = 'h'
          paramaters.unshift('m')
        
        when :group
          @type = 'h'
          paramaters.unshift('g')
          
        when :who
          @type = 'h'
          paramaters.unshift('w')          
        
        when :who_global
          @type = 'h'
          paramaters.unshift("w\001")
        
        when :nop
          @type = 'n'
        end
        
      @paramaters = paramaters 
    end
    
    def send(socket)
      socket.send pack_data, 0  # no seperation between length and type, length byte is NOT counted in length
    end
    
    def dump
      packet = pack_data
      i = 0
      packet.each_byte { |b|
        puts "#{i}\t#{b}\t#{b.chr}"
      }
    end
      
  private
    def pack_data
      data = @type # no 001 seperation between type and the first param
      @paramaters.each { |p|
        data += p + 1.chr # parameters are seperated by 001
      }
      data[-1] = 0.chr # remove the spurious final 001 and null terminate the packet
      
      return "#{data.length.chr}#{data}"
    end

end