require_relative 'config'
require_relative 'sprite'

class Hero < Sprite
  BaseMoveSpeed = 2
  MaxMoveSpeed = Config::TILE_SIZE
  JumpPower = 40.0

  attr_accessor :state, :dx, :dy, :on_ground

  def initialize(x, y, w = 16.0, h = 16.0, path = Config::SPRITE_PURE_WHITE)
    super
    @dy = 0.0
    @dx = 0.0
    @on_ground = false
  end

  def input(horizontal, vertical)
    state ||= :idle

    # NOTE: using magic values for now, until the feel is right...
    @dx += horizontal * 2.0 # BaseMoveSpeed
    @dx *= 0.67
    gf = vertical > 0.0 && @dy > 0.0 ? 0.5 : 1.0
    @dy -= Config::GRAVITY * gf
    if @on_ground && vertical > 0.0
      @dy += 20.0 # JumpPower
    end

    # movement speed is clamped to a suitable maximum to prevent tunneling through tiles
    @dx = @dx.clamp(-MaxMoveSpeed, MaxMoveSpeed)
    @dy = @dy.clamp(-MaxMoveSpeed, MaxMoveSpeed)
  end
end
