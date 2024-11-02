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

  # TODO: add tests for the conditions to avoid having to rethink this when adding velocities ...
  def resolve_tile_collision(dynamic, tile)
    overlap_x = if dynamic.x < tile.x
                  (dynamic.x + dynamic.w) - tile.x
                else
                  dynamic.x - (tile.x + tile.w)
                end

    overlap_y = if dynamic.y < tile.y
                  (dynamic.y + dynamic.h) - tile.y
                else
                  dynamic.y - (tile.y + tile.h)
                end

    if overlap_x.abs < overlap_y.abs
      dynamic.vx = 0.0
      dynamic.x = if dynamic.x < tile.x
                    tile.x - dynamic.w
                  else
                    tile.x + tile.w
                  end
    else
      dynamic.vy = 0.0
      dynamic.y = if dynamic.y < tile.y
                    tile.y - dynamic.h
                  else
                    dynamic.on_ground = true
                    tile.y + tile.h
                  end
    end
  end

  # TODO: move to Hero class
  def move_player(player, world)
    player.on_ground = false # NOTE: should reset state overall or think of state management
    # x-axis
    player.x += player.dx
    collision = world.find { |tile| tile.intersect_rect? player }
    if collision
      if player.dx > 0
        player.x = collision.x - player.w
      elsif player.dx < 0
        player.x = collision.x + collision.w
      end
      player.dx = 0
    end

    # y-axis movement and collisions
    player.y += player.dy
    collision = world.find { |tile| tile.intersect_rect? player }
    return unless collision

    if player.dy > 0
      player.y = collision.y - player.h
    elsif player.dy < 0
      player.on_ground = true
      player.y = collision.y + collision.h
    end
    player.dy = 0.0

    # hazards

    # enemies
  end

  def update
    move_player(@hero, @level.tiles)
  end

  def render
    outputs.background_color = [0, 0, 0]
    outputs.labels << [10.from_left, 200.from_top, 'GameOff \'24 framework tests', 255, 255, 255, 255]

    outputs.solids << @level.tiles

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

def reset_game(args)
  puts 'Game reset!'
  args.state.game = Game.new(args)
  args.state.game.args = args
end

def boot(_args)
  puts 'Game booted!'
  # TODO: on a test, debug or release run and set flags accordingly
  # E.g debug assertation setup & skip window creation & what not on tests..
end
