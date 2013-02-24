#!/usr/bin/env ruby
require './icb_packet'
require './icb_read'
require './user_input'

require "io/wait"
require 'readline'
require 'getoptlong'
require 'thread'

$screen_semaphore = Mutex.new

nickname        = ENV['USER']
default_group   = 'IcyBee'
password        = ''

opts = GetoptLong.new(
  [ '--help',     '-h', GetoptLong::NO_ARGUMENT ],
  [ '--group',    '-g', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--nickname', '-n', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--password', '-p', GetoptLong::OPTIONAL_ARGUMENT]
)

usage = "ruBee {options}
  -g group, --group group    group to join at startup
  -h, --help                 this message
  -n, --nickname nickname    nickname to use
  -p, --password password    login using password 
"

opts.each do |opt, arg|
  case opt
    when '--help'
      puts usage
      exit 0
    when '--group'
      if arg == '' then
        puts usage
        exit 0
      end
      default_group = arg
    when '--nickname'
      if arg == '' then
        puts usage
        exit 0
      end
      nickname = arg
   when '--password'
     if arg == '' then
        puts usage
        exit 0
      end
      password = arg
    else
      puts usage
      exit 0
  end
end 

TERMINAL_STATE = `stty -g`
at_exit { system "stty #{TERMINAL_STATE}" }

puts "Connecting..."

$icb_socket  = IcbPacket::icb_socket
protocol     = IcbPacket::get_packet($icb_socket)
login_packet = IcbPacket::new(:login, [nickname, nickname, default_group, 'login', ''])
login_packet.send($icb_socket)

login_result = IcbPacket::get_packet($icb_socket)

unless login_result[0] == 'a' 
  puts "login failed.\n#{login_result[2..login_result.length]}"
  exit
end

$reader_thread = IcbRead.new 
$user_thread   = UserInput.new.join
#
# Execution never reaches this point.  
#
# We now have two threads, one for user input and one for 
# reading from the icb seerver.  The nice thing about doing it this way is that the class names
# will show up when listing or debugging the threads.  use:
# Thread.list.each {|t| p t}
# to display all of the threads and their status
#




