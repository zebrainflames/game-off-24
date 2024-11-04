require_relative 'lib/vectormath_2d'
require_relative 'config'
require_relative 'hero'
require_relative 'level'

class Game
  attr_gtk

  attr_accessor :level

  def initialize(args)
    @hero = Hero.new(128.from_left, args.grid.h / 2.0, 16, 16, Config::SPRITE_HERO)
    @level = Level.new
    @hero.x = @level.player_spawn.x
    @hero.y = @level.player_spawn.y
  end

  def reload
    level.reload_tileset
    @hero.x = @level.player_spawn.x
    @hero.y = @level.player_spawn.y
  end

  def tick
    input
    update
    render
  end

  def input
    @hero.input(inputs.left_right, inputs.up_down)

    return unless inputs.keyboard.key_down.f

    args.gtk.toggle_window_fullscreen
  end

  # TODO: move to world?
  def move_entity(entity, world)
    entity.on_ground = false # NOTE: should reset state overall or think of state management
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

    # hazards

    # enemies
  end

  def update
    move_entity(@hero, @level.collideables)

    @level.key_collisions @hero

    return if @level.complete
    return unless @level.entity_on_exit? @hero

    puts 'player on exit!'
  end

  def render
    outputs.background_color = [0, 0, 0]
    outputs.labels << [10.from_left, 200.from_top, "GameOff '24 framework tests", 255, 255, 255, 255]

    outputs.solids << @level.tiles

    outputs.solids << @level.exit

    outputs.solids << @level.key_tiles

    outputs.solids << @level.doors

    outputs.sprites << @hero

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
