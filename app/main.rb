require_relative 'config'
require_relative 'hero'
require_relative 'level'

class Game
  attr_gtk

  attr_accessor :level, :hero

  def initialize(args)
    @hero = Hero.new(128.from_left, args.grid.h / 2.0, 16, 16, Config::SPRITE_DEFAULT)
    @level = Level.new
    @hero.x = @level.player_spawn.x
    @hero.y = @level.player_spawn.y
  end

  def reload
    load_level(level.idx)
  end

  def load_level(idx)
    @level = Level.new(idx)
    @hero.x = @level.player_spawn.x
    @hero.y = @level.player_spawn.y
  end

  def tick
    input
    update
    render
  end

  def input
    @hero.check_rope_collisions(@level.collideables)
    @hero.compute_velocity(inputs)

    args.gtk.toggle_window_fullscreen if inputs.keyboard.key_down.f
  end

  # TODO: move to world?
  def move_entity(entity, world)
    entity.on_ground = false
    # x-axis
    entity.x += entity.dx
    collision = world.find { |collider| collider.intersect_rect? entity }
    if collision
      if entity.dx > 0
        entity.x = collision.x - entity.w
      elsif entity.dx < 0
        entity.x = collision.x + collision.w
      end
      entity.dx = 0
    end

    # y-axis movement and collisions
    entity.y += entity.dy
    collision = world.find { |tile| tile.intersect_rect? entity }
    return unless collision

    if entity.dy > 0
      entity.y = collision.y - entity.h
    elsif entity.dy < 0
      entity.on_ground = true
      entity.y = collision.y + collision.h
    end
    entity.dy = 0.0
  end

  def update
    move_entity(@hero, @level.collideables)

    @level.key_collisions @hero

    return if @level.complete
    return unless @level.entity_on_exit? @hero

    puts 'player on exit!'
    @level = @level.next_level
  end

  def render
    outputs.background_color = [32, 40, 61]
    outputs.labels << [10.from_left, 130.from_top, "rope state: #{@hero.state}", 255, 255, 255, 255]

    # TODO: use static tiles
    outputs.sprites << @level.tiles.map do |tile|
      tile.merge({ path: 'sprites/sprites.png', source_x: 48, source_y: 80, source_w: 16, source_h: 16 })
    end

    outputs.sprites << @level.exit
    outputs.sprites << @level.key_tiles
    outputs.sprites << @level.doors
    outputs.sprites << @hero.sprites

    unless @hero.state == :idle
      outputs.sprites << { x: inputs.mouse.x, y: inputs.mouse.y, w: 12.0, h: 12.0, r: 220, b: 220, g: 220, a: 180,
                           anchor_x: 0.5, anchor_y: 0.5, path: :pixel }
      unless @hero.rope_head.nil?
        outputs.solids << @hero.rope_head
        mid = @hero.rope_midpoint
        outputs.sprites << {
          x: @hero.x + mid.x,
          y: @hero.y + mid.y,
          w: 4.0,
          h: @hero.rope_length - 8,
          path: :pixel,
          r: 220.0, g: 220, b: 220, a: 180,
          achor_x: 0.5, anchor_y: 0.5,
          angle: geometry.angle_from(@hero, @hero.rope_head) - 90
        }
      end
    end

    outputs.primitives << args.gtk.current_framerate_primitives
  end
end

def tick(args)
  reset_game args unless args.state.game
  args.state.game.tick
end

def go
  $gtk.args.state.game
end

def reload
  $gtk.args.state.game.reload
end

def reset_game(args)
  puts 'Game reset!'
  args.state.game = Game.new(args)
  args.state.game.args = args
end

def reset(_args)
  puts 'reset called'
end

def boot(_args)
  puts 'Game booted!'
  # TODO: on a test, debug or release run and set flags accordingly
  # E.g debug assertation setup & skip window creation & what not on tests..
end

$gtk.warn_array_primitives!
