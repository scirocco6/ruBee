require 'etc'

$nick_list        = []        # array of nicknames for /m tabbing

$color            = true      #enable or disable color
$open_color       = :magenta
$im_color         = :green
$status_color     = :yellow
$error_color      = :red
$important_color  = :yellow
$command_color    = :cyan
$header_color     = :blue
$server_color     = :yellow
$who_color        = :white

$nickname         = ENV['USERNAME']
$nickname         = ENV['USER'] if $nickname == ''
$default_group    = 'ruBee'
$password         = ''
$default_host     = 'default.icb.net'
$default_port     = '7326'