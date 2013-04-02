class String
  # colorization
  def fg_color(fg)
    color = ''
    case fg
      when :black
        color = 33
      when :red 
        color = 31
      when :green
        color = 32
      when :yellow
        color = 33
      when :blue
        color = 34
      when :magenta
        color = 35
      when :cyan
        color = 36 
      when :white
        color = 37
      else
        self
        return
    end
    "\e[#{color}m#{self}\e[0m"
  end
end
