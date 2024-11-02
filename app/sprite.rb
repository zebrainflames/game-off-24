require_relative 'config'

class Sprite
  attr_sprite

  def initialize(x, y, w = 16.0, h = 16.0, path = Config::SPRITE_PURE_WHITE)
    @x = x
    @y = y
    @w = w
    @h = h
    @path = path
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_sprite @x, @y, @w, @h, @path
  end
end
