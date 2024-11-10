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
    outputs.background_color = { r: 32, g: 40, b: 61 }
    outputs.labels << { x: 10.from_left, y: 130.from_top, text: "rope state: #{@hero.state}", r: 255, g: 255, b: 255 }

    # TODO: use static tiles
    outputs.sprites << @level.tiles.map do |tile|
      tile.merge({ path: 'sprites/sprites.png', source_x: 48, source_y: 80, source_w: 16, source_h: 16 })
    end

    outputs.sprites << @level.exit
    outputs.sprites << @level.key_tiles
    outputs.sprites << @level.doors
    outputs.sprites << @hero.body_sprite
    outputs.sprites << @hero.rope_sprites(inputs)

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
