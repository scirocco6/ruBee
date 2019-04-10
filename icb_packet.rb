class IcbPacket
  require 'socket'

  public
    def self.icb_socket
      return(TCPSocket.new($default_host, $default_port))
    end

    def self.get_packet(socket)
      return '' unless socket
<<<<<<< HEAD

      packet_size = socket.read(1) # read blocks until correct # of chars received
=======
      
      packet_size = socket.read(1)            # read blocks until correct # of chars received
>>>>>>> 45b876ade64c460e43a3930907f6e1a862199b7c
      return(socket.read(packet_size[0].ord)) # recv returns with as many characters as are ready
    end

    def self.decode(packet)
      case packet[0,1]
        when 'b' # open message
          (from, text) = packet.split 1.chr
          return "<#{from[1, from.length]}>".fg_color($open_color) << " #{text}"

        when 'c' # personal message
          (from, text) = packet.split 1.chr
          return "<*#{from[1, from.length]}*>".fg_color($im_color) << " #{text}"

        when 'd' # status message
          (category, text) = packet.split 1.chr
          return "[=#{category[1, category.length]}=]".fg_color($status_color) << " #{text}"

        when 'e' # error message
          return "[=Error=]".fg_color($error_color) << " #{packet[1, packet.length]}"

        when 'f' # important message
          (category, text) = packet.split 1.chr
          return "[!#{category[1, category.length]}!]".fg_color($important_color) << "#{text}"

        when 'g' # exit
          exit 0

        when 'i' # command output
          case packet[0,3]
            when 'ico' # generic command output
               return "#{packet[3, packet.length]}".fg_color($command_color)
            when 'iec' # end of output terminator in theory there should never be any actual message from this
              return "#{packet[3, packet.length]}".fg_color($command_color)
            when 'iwh' # output the who header
              return "   Nickname          Idle       Sign-On        Account".fg_color($header_color)
            when 'iwl' # item in a who listing
              (type, flag, nick, idle, respc, login, user, host) = packet.split 1.chr
              account = "#{user}@#{host}"
              flag = '*' if flag == 'm'

              seconds = idle.to_i

              days     = seconds / (24 * 60 * 60)
              seconds -= days * 24 * 60 * 60
              hours    = seconds / (60 * 60)
              seconds -= hours * 60 * 60
              minutes  = seconds / 60
              seconds -= minutes * 60

              idle = ''
              idle << "#{days}d"    if days     > 0
              idle << "#{hours}h"   if hours    > 0
              idle << "#{minutes}m" if minutes  > 0
              idle << "#{seconds}s" if seconds  > 0
              idle = '-' if idle == ''

              idle.gsub!(/([a-z])(\d)/, '\1,\2')
              return "#{flag}#{nick.ljust(13)}#{idle.rjust(18)}#{Time.at(login.to_i).strftime("%m/%d %H:%M").rjust(13)}  #{account}".fg_color($who_color)
            else
              return "Unknown packet of type '#{packet[0,1]}'\n#{packet}".fg_color($error_color)
          end

        when 'k' # beep
          return "[=Beep!=]".fg_color($im_color) << " #{packet[1, packet.length]} sent you a beep!"

        when 'l' # ping
          return "[=Server=]".fg_color($server_color) << " ping #{packet[1, packet.length]}"

        when 'm' # ping
          return "[=Server=]".fg_color($server_color) << " pong #{packet[1, packet.length]}"

        when 'n' # NOP packet
          return "[=Server=]".fg_color($server_color) << " NOP!!@"

        else
          return "Unknown packet of type '#{packet[0,1]}'\n#{packet}".fg_color($error_color)
      end
    end

    def initialize(type, parameters = [])
      case type
        when :beep
#          @type = 'k' # default.icb.net doesn't handle beep packets use command packet beep instead
          @type = 'h'
          parameters.unshift('beep')

        when :login
          @type = 'a'

        when :open
          @type = 'b'

        when :private
          @type = 'h'
          parameters.unshift('m')

        when :group
          @type = 'h'
          parameters.unshift('g')

        when :who
          @type = 'h'
          parameters.unshift('w')

        when :who_global
          @type = 'h'
          parameters.unshift("w\001")

        when :nop
          @type = 'n'
        end

      @parameters = parameters
    end

    def send(socket)
      socket.send pack_data, 0  # no separation between length and type, length byte is NOT counted in length
    end

    def dump
      packet = pack_data
      i = 0
      #packet.each_byte { |b|
        #puts "#{i}\t#{b}\t#{b.chr}"
        #`echo "#{i}\t#{b}\t#{b.chr}" >> dump.txt`
      #}
    end

  private
    def pack_data
      data = @type # no 001 seperation between type and the first param
      @parameters.each { |p|
        data += p + 1.chr # parameters are separated by 001
      }
      data[-1] = 0.chr # remove the spurious final 001 and null terminate the packet

      return "#{data.length.chr}#{data}"
    end

end
