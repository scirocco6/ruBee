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
          return "<#{from[1, from.length]}>".fg_color(:magenta) << " #{text}"
          
        when 'c' # personal message
          (from, text) = packet.split 1.chr
          return "<*#{from[1, from.length]}*>".fg_color(:green) << " #{text}"
        
        when 'd' # status message
          (category, text) = packet.split 1.chr
          return "[=#{category[1, category.length]}=]".fg_color(:yellow) << " #{text}"        
          
        when 'e' # error message
          return "[=Error=]".fg_color(:red) << " #{packet[1, packet.length]}"
          
        when 'f' # important message
          (category, text) = packet.split 1.chr
          return "[!#{category[1, category.length]}!]".fg_color(:brown) << "#{text}"
          
        when 'g' # exit
          exit 0
          
        when 'i' # command output 
          case packet[0,3]
            when 'ico'
               return "#{packet[3, packet.length]}".fg_color(:cyan)
            when 'iec'
              return "#{packet[3, packet.length]}".fg_color(:yellow)
            when 'iwh' # output the who header
              return "   Nickname          Idle       Sign-On        Account".fg_color(:blue)
            when 'iwl' # item in a who listing
              (type, flag, nick, idle, respc, login, user, host) = packet.split 1.chr
              account = "#{user}@#{host}"
              flag = '*' if flag == 'm'
              
              seconds = idle.to_i

              days     = seconds / (24 * 60 * 60);
              seconds -= days * 24 * 60 * 60;
              hours    = seconds / (60 * 60);
              seconds -= hours * 60 * 60;
              minutes  = seconds / 60;
              seconds -= minutes * 60;
                      
              idle = ''
              idle << "#{days}d"    if days     > 0
              idle << "#{hours}h"   if hours    > 0
              idle << "#{minutes}m" if minutes  > 0
              idle << "#{seconds}s" if seconds  > 0
              idle = '-' if idle == ''
              
              return "#{flag}#{nick.ljust(13)}#{idle.rjust(14)}#{Time.at(login.to_i).strftime("%m/%d %H:%M").rjust(13)}  #{account}".fg_color(:white)
          end
          
        when 'k' # beep
          return "[=Beep!=]".fg_color(:green) << " #{packet[1, packet.length]} sent you a beep!"
        
        when 'l' # ping
          return "[=Server=]".fg_color(:yellow) << " ping #{packet[1, packet.length]}" 
           
        when 'm' # ping
          return "[=Server=]".fg_color(:yellow) << " pong #{packet[1, packet.length]}"
          
        when 'n' # NOP packet
          return "[=Server=]".fg_color(:yellow) << " NOP!!@"
          
        else
          return "Unknown packet of type '#{packet[0,1]}'\n#{packet}".fg_color(:red)
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