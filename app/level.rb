require_relative 'config'

class Level
  attr_reader :tiles

  @@level_data = [
    # level 1
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1,
      1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0,
      1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1
    ]
  ]

  def initialize(idx = 1)
    @idx = idx
  end

  def reload_tileset
    puts 'constructing tileset'
    ts = Config::TILE_SIZE
    @tiles = []
    current.each_with_index do |tile_id, idx|
      next if tile_id.zero?

      x = idx % 16
      y = 9 - (idx / 16).floor.to_i
      @tiles << { x: x * ts, y: y * ts, w: ts, h: ts, r: 20, g: 255, b: 255, a: 255,
                  primitive_marker: :solid }
    end
  end

  def tiles
    reload_tileset if @tiles.nil?
    @tiles
  end

  def current
    @@level_data[@idx - 1]
  end
end
