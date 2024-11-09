require_relative 'config'

class Sprite
  attr_sprite

  def initialize(x, y, w = 16.0, h = 16.0, path = Config::SPRITE_PURE_WHITE, sx = 0, sy = 0, sw = 16, sh = 16)
    @x = x
    @y = y
    @w = w
    @h = h
    @source_x = sx
    @source_y = sy
    @source_w = sw
    @source_h = sh
    @ts = sw # NOTE: this might break something ;)
    @path = path
    @flip_h = false
    @flip_v = false
    @frame_x = 0
    @frame_y = 0
    @angle = 0.0
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_sprite_3 @x, @y, @w, @h, @path, @angle, 255, 255, 255, 255, @frame_x, @frame_y, 16, 16, @flip_h, @flip_v, 0.5, 0.5,
                           @source_x, @source_y, @source_w, @source_h
  end
end
