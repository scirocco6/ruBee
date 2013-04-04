require './icb_packet'
require 'thread'
require 'readline'

class UserInput < Thread
  def initialize
    super do
      next_nic = 0
      comp = proc do |s|
        if $nick_list.size > 0
          s.sub!(/^\/m \w+\s*/,'')
          s.prepend "/m #{$nick_list[next_nic]} "
          next_nic = next_nic == $nick_list.size - 1 ? 0 : next_nic + 1 if $nick_list.size > 1
          s
        end
      end
      Readline.completer_quote_characters       = ''
      Readline.completer_word_break_characters  = ''
      Readline.completion_append_character      = ''
      Readline.completion_proc                  = comp

      while 1 do
        system "stty raw -echo cbreak"
        if $stdin.wait
          line = ''
          $screen_semaphore.synchronize do
            system "stty #{TERMINAL_STATE}"
            line = Readline.readline('', true)
          end

          next unless line
          unless line.start_with? '/'
            IcbPacket::new(:open, [line]).send($icb_socket)
          else
            input = line.split
            if input.first == '/beep'
              IcbPacket::new(:beep, [input.last]).send($icb_socket)
            elsif line =~ /^\/m\s(\w+)(\s.*)/
              $nick_list.unshift $1 unless $nick_list.index $1
              IcbPacket::new(:private, [$1 << $2]).send($icb_socket)
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
