require_relative 'lib/vectormath_2d'
require_relative 'config'
require_relative 'hero'
require_relative 'level'

class Game
  attr_gtk

  attr_accessor :level

  def initialize(args)
    @hero = Hero.new(args.grid.w / 2.0, args.grid.h / 2.0, 16, 16, Config::SPRITE_HERO)
    @level = Level.new
  end

  def tick
    input
    update
    render
  end

  def input
    @hero.update(inputs.left_right, inputs.up_down)

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
      dynamic.x = if dynamic.x < tile.x
                    tile.x - dynamic.w
                  else
                    tile.x + tile.w
                  end
    else
      dynamic.y = if dynamic.y < tile.y
                    tile.y - dynamic.h
                  else
                    tile.y + tile.h
                  end
    end
  end

  def find_tile_collisions(dynamic, tiles)
    tiles.map do |tile|
      args.geometry.find_intersect_rect(dynamic, tile)
    end.compact
  end

  def handle_collisions(max_iterations = 3)
    iters = 0

    # tiles
    loop do
      collisions = find_tile_collisions(@hero, @level.tiles)
      break if collisions.empty? || iters >= max_iterations

      collisions.each do |collider|
        resolve_tile_collision(@hero, collider)
      end

      iters += 1
    end
    # hazards

    # enemies
  end

  def update
    handle_collisions
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
  puts 'GAME RESET'
  args.state.game = Game.new(args)
  args.state.game.args = args
end

def boot(_args)
  puts 'Game booted!'
  # TODO: on a test, debug or release run and set flags accordingly
  # E.g debug assertation setup & skip window creation & what not on tests..
end
