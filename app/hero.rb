require_relative 'config'
require_relative 'sprite'

class Hero < Sprite
  BaseMoveSpeed = 2
  MaxMoveSpeed = Config::TILE_SIZE
  JumpPower = 40.0

  attr_accessor :state, :dx, :dy, :on_ground, :rope_head

  def initialize(x, y, w = 32.0, h = 32.0, path = Config::SPRITE_DEFAULT)
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
  def body_sprite
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
    self
  end

  # TODO: rope starting point should be offset from the left bottom corner of the player character
  def rope_sprites(inputs)
    return [] if @state == :idle

    sprites = []

    sprites << { x: inputs.mouse.x, y: inputs.mouse.y, w: 12.0, h: 12.0, r: 220, b: 220, g: 220, a: 180,
                 anchor_x: 0.5, anchor_y: 0.5, path: :pixel }
    sprites << @rope_head
    mid = rope_midpoint
    sprites << {
      x: @x + mid.x,
      y: @y + mid.y,
      w: 4.0,
      h: rope_length - 8,
      path: :pixel,
      r: 220.0, g: 220, b: 220, a: 180,
      achor_x: 0.5, anchor_y: 0.5,
      angle: $geometry.angle_from(self, @rope_head) - 90
    }
  end

  def dir_from_to(from, to)
    dx = to.x - from.x
    dy = to.y - from.y
    len = Math.sqrt(dx * dx + dy * dy)
    dx /= len
    dy /= len
    [dx, dy]
  end

  def spring_force(pos_x, pos_y, anchor_x, anchor_y, dx, dy, stiffness: 0.01, damping: 0.05)
    offset_x = anchor_x - pos_x
    offset_y = anchor_y - pos_y
    spf_x = offset_x * stiffness
    spf_y = offset_y * stiffness
    damp_x = -dx * damping
    damp_y = -dy * damping
    [spf_x + damp_x, spf_y + damp_y]
  end

  # compute_velocity is the main movement handling function in the game currently.
  # it does all the key things relating to physics handling, by computing the dx and dy
  # values per frame (velocities)
  # NOTE: using magic values for now, until the feel is right...
  def compute_velocity(inputs)
    ## Rope handling - done first to ensure the players movement state is correct for velocity updates
    if inputs.mouse.button_left
      dx, dy = dir_from_to(self, inputs.mouse)
      pa = Math.atan2(dy, dx)
      @rope_head.angle = pa
      if @state == :idle
        @rope_head.x = @x + 16
        @rope_head.y = @y + 16
        @state = :shooting_rope
        @prev_rope_head = @rope_head
      end

      if @state == :shooting_rope
        @prev_rope_head = @rope_head
        @rope_head.x += dx * 12.4
        @rope_head.y += dy * 12.4
      end
    else
      @state = :idle
      @rope_head.x = -100.0
      @rope_head.y = -100.0
    end

    ## Player velocity updates, depending on movement state (i.e. rope is attached or not)
    if @state == :rope_attached
      f_x, f_y = spring_force(@x, @y, @rope_head.x, @rope_head.y, @dx, @dy, stiffness: 0.01, damping: 0.03)
      @dx += f_x
      @dy += f_y

      # allow the player to also move a bit when using the ninja rope
      @dx += inputs.left_right * 0.7
      @dy += inputs.up_down * 0.7
    else
      @dx += inputs.left_right * 2.0 # BaseMoveSpeed
      @dx *= 0.67

      gf = inputs.up_down > 0.0 && @dy > 0.0 ? 0.5 : 1.0
      @dy -= Config::GRAVITY * gf
      if @on_ground && inputs.up_down > 0.0
        @dy += 20.0 # JumpPower
      end
    end
    # movement speed is clamped to a suitable maximum to prevent tunneling through tiles
    @dx = @dx.clamp(-MaxMoveSpeed, MaxMoveSpeed)
    @dy = @dy.clamp(-MaxMoveSpeed, MaxMoveSpeed)
  end
end
