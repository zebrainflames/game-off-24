require_relative 'config'
require_relative 'sprite'

class Hero < Sprite
  BaseMoveSpeed = 2
  MaxMoveSpeed = Config::TILE_SIZE
  JumpPower = 40.0

  attr_accessor :state, :dx, :dy, :on_ground, :rope_head

  def initialize(x, y, w = 16.0, h = 16.0, path = Config::SPRITE_DEFAULT)
    super
    @dy = 0.0
    @dx = 0.0
    @on_ground = false
    @rope_head = { x: -100, y: -100, w: 8.0, h: 8.0, r: 20, b: 20, g: 255, a: 255,
                   anchor_x: 0.5, anchor_y: 0.5 }
    @state = :idle
    @frame_y = 16 * 2 # starting from idle anim frames
  end

  def rope_length
    x = @rope_head.x - @x
    y = @rope_head.y - @y
    Math.sqrt(x * x + y * y)
  end

  def rope_midpoint
    x = (@rope_head.x - @x) / 2.0
    y = (@rope_head.y - @y) / 2.0
    { x: x, y: y }
  end

  # NOTE: this is a naive implementation; it will tunnel into tiles sometimes. If high speeds for the rope are
  # needed would need to raycast or at least do sampling.
  def check_rope_collisions(world)
    return unless @state == :shooting_rope

    rope_collision = world.find { |collider| collider.intersect_rect? @rope_head }
    return unless rope_collision

    @state = :rope_attached
  end

  ## TODO: move rest of player drawing here
  def sprites
    @flip_h = true if dx < 0.0
    @flip_h = false if dx > 0.0
    @frame_y = if dx.abs <= 0.01
                 16 * 2
               else
                 16 * 3
               end

    x_index = Numeric.frame_index start_at: 0,
                                  frame_count: 3,
                                  repeat: true,
                                  hold_for: 8
    @frame_x = 16 * x_index
    # @frame_y = 16 * 2
    self
  end

  def compute_velocity(inputs)
    ## Rope handling
    if inputs.mouse.button_left
      dx = inputs.mouse.x - x
      dy = inputs.mouse.y - y
      len = Math.sqrt(dx * dx + dy * dy)
      dx /= len
      dy /= len
      pa = Math.atan2(dy, dx)
      @rope_head.angle = pa
      if @state == :idle
        @rope_head.x = @x
        @rope_head.y = @y + 16 ## NOTE: will need to remove/rethink this offset if all objects are moved to (0.5,0.5) achors when changing to sprites
        @state = :shooting_rope
        @prev_rope_head = @rope_head
      end

      if @state == :shooting_rope
        @prev_rope_head = @rope_head
        @rope_head.x += dx * 12.4
        @rope_head.y += dy * 12.4
      end

      # puts "I'm attached!" if @state == :rope_attached
    else
      @state = :idle
      @rope_head.x = -100.0
      @rope_head.y = -100.0
    end

    ## Pleyer movement
    # NOTE: using magic values for now, until the feel is right...
    @dx += inputs.left_right * 2.0 # BaseMoveSpeed
    @dx *= 0.67

    gf = inputs.up_down > 0.0 && @dy > 0.0 ? 0.5 : 1.0
    @dy -= Config::GRAVITY * gf
    if @on_ground && inputs.up_down > 0.0
      @dy += 20.0 # JumpPower
    end

    # TODO: this isn't yet a satisfying way to swing on the rope, will need to be improved
    if @state == :rope_attached
      @dy += (@rope_head.y - @y) * 0.02
      @dx += (@rope_head.x - @x) * 0.01
    end

    # movement speed is clamped to a suitable maximum to prevent tunneling through tiles
    @dx = @dx.clamp(-MaxMoveSpeed, MaxMoveSpeed)
    @dy = @dy.clamp(-MaxMoveSpeed, MaxMoveSpeed)
  end
end
