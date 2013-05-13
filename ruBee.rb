#!/usr/bin/env ruby
require './defaults'
require './string'
require './icb_packet'
require './icb_read'
require './user_input'

require "io/wait"
require 'readline'
require 'getoptlong'
require 'thread'
require 'pathname'
require 'curses'
include Curses

#puts "Starting"
#exit






trap('INT', 'SIG_IGN') do
  system "stty #{TERMINAL_STATE}"
  yon = Readline.readline(prompt="Really quit?", false)
  exit if (line =~ /^[Yy]$/) or (line.upcase! == "YES")
end

#
# find home dir in a way that works on windows and unix and ruby 1.8.7
#
homes = ["HOME", "HOMEPATH"]
realHome = homes.detect {|h| ENV[h] != nil}
pn = Pathname.new("#{ENV[realHome]}/.ruBeerc")

if pn.exist?
  load pn
end

$screen_semaphore = Mutex.new

opts = GetoptLong.new(
  ['--help',      '-?', GetoptLong::NO_ARGUMENT ],
  ['--group',     '-g', GetoptLong::REQUIRED_ARGUMENT ],
  ['--nickname',  '-n', GetoptLong::REQUIRED_ARGUMENT ],
  ['--password',  '-p', GetoptLong::REQUIRED_ARGUMENT],
  ['--host',      '-h', GetoptLong::REQUIRED_ARGUMENT],
  ['--port',      '-s', GetoptLong::REQUIRED_ARGUMENT],
  ['--nocolor',   '-m', GetoptLong::NO_ARGUMENT],
  ['--clear',     '-c', GetoptLong::NO_ARGUMENT]
)

usage = "ruBee {options}
  -n nickname, --nickname nickname  nickname to use
  -p password, --password password  login using password
  -g group,    --group group        group to join at startup
  -w,          --who                perform a global who instead of logging in
  -w group,    --who group          who a group instead of logging in
  -w @nickname --who nickname       who the group nickname is in instead of logging in
  -h host,     --host host          connect to server on host
  -s port,     --port port          connect port number port
  -c,          --clear              wipe the command line arguments
  -m,          --nocolor            disable text coloration
  -?,          --help               this message
"

wipe = false
opts.each do |opt, arg|
  case opt
    when '--help'
      puts usage
      exit 0
    when '--group'
      if arg == ''
        puts usage
        exit 0
      end
      $default_group = arg
    when '--nickname'
      if arg == ''
        puts usage
        exit 0
      end
      $nickname = arg
   when '--password'
     if arg == ''
        puts usage
        exit 0
      end
      $password = arg
      wipe = true
    when '--host'
      if arg == ''
        puts usage
        exit 0
      end
      $default_host = arg
    when '--port'
      if arg == ''
        puts usage
        exit 0
      end
      $default_port = arg
    when '--nocolor'
      $color = false
    when '--clear'
      wipe = true
    else
      puts usage
      exit 0
  end
end

$PROGRAM_NAME = 'ruBee' if wipe

TERMINAL_STATE = `stty -g`
at_exit { system "stty #{TERMINAL_STATE}" }

puts "Connecting..."

$icb_socket  = IcbPacket::icb_socket
protocol     = IcbPacket::get_packet($icb_socket)
login_packet = IcbPacket::new(:login, ['ruBee', $nickname, $default_group, 'login', $password, ''])

login_packet.send($icb_socket)
login_result = IcbPacket::get_packet($icb_socket)

unless login_result[0] == 'a' 
  puts "login failed.\n#{login_result[1..login_result.length]}"
  exit
end

$reader_thread = IcbRead.new
$user_thread   = UserInput.new.join
#
# Execution never reaches this point.  
#
# We now have two threads, one for user input and one for 
# reading from the icb server.  The nice thing about doing it this way is that the class names
# will show up when listing or debugging the threads.  use:
# Thread.list.each {|t| p t}
# to display all of the threads and their status
#

