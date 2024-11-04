require_relative 'config'

class Level
  attr_reader :tiles, :player_spawn, :exit, :complete

  # LEVEL_TILE_TYPES:
  # 0 Empty
  # 1 Wall
  # 2 Target
  # 3 key
  # 4 door

  SpawnTile = 2
  TargetTile = 3
  KeyTile = 4
  DoorTile = 5

  # Key and door combinations; this is a ugly way to structure things...
  @doors = { A: {}, B: {}, C: {}, D: {} }
  # key ids:
  A = 11
  B = 12
  # door ids
  H = 21
  J = 22

  @@keys_ids = [A, B]
  @@door_ids = [H, J]

  @@tileset_width = 16 * 2
  @@level_data = [
    # level 1
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
      0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
      A, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, H, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]
  ]

  def initialize(idx = 1)
    @idx = idx
    @player_spawn = { x: 0.0, y: 0.0 }
    # TODO: rethink initialization...
    @exit = { x: -10.0, y: -10.0, w: 32.0, h: 32.0 }
    @keys = {}
    reload_tileset
  end

  def entity_on_exit?(entity)
    return unless entity.intersect_rect? @exit

    @complete = true
    true
  end

  def key_collisions(entity)
    @keys.each do |key, tile|
      next if tile&.picked_up

      next unless entity.intersect_rect? tile

      tile.picked_up = true
      open_door key
    end
  end

  def collideables
    tiles + closed_doors
  end

  def doors
    @doors.values
  end

  def closed_doors
    @doors.values.reject { |door| door.is_open }
  end

  def key_tiles
    @keys.values.reject { |tile| tile.picked_up }
  end

  def reload_tileset
    puts 'constructing tileset, reloading level'
    ts = Config::TILE_SIZE
    @tiles = []
    @complete = false
    current.each_with_index do |tile_id, idx|
      next if tile_id.zero?

      x = idx % @@tileset_width
      y = 9 - (idx / @@tileset_width).floor.to_i
      if tile_id == SpawnTile
        @player_spawn.x = x * ts
        @player_spawn.y = y * ts
        next
      end
      if tile_id == TargetTile
        @exit =
          { x: x * ts, y: y * ts, w: ts, h: ts, r: 120, g: 255, b: 20, a: 220, primitive_marker: :borders }
        next
      end

      if @@keys_ids.include? tile_id
        @keys ||= {}
        @keys[tile_id] =
          { x: x * ts, y: y * ts, w: ts, h: ts, r: 150, b: 150, g: 0, a: 180, primitive_marker: :borders }
        next
      end

      if @@door_ids.include? tile_id
        @doors ||= {}
        @doors[tile_id - 10] =
          { x: x * ts, y: y * ts, w: ts, h: ts, r: 100, b: 150, g: 0, a: 180, primitive_marker: :borders,
            is_open: false }
        next
      end

      @tiles << { x: x * ts, y: y * ts, w: ts, h: ts, r: 20, g: 255, b: 255, a: 255,
                  primitive_marker: :solid }
    end
  end

  def tiles
    reload_tileset if @tiles.nil?
    @tiles
  end

  private

  def open_door(id)
    puts "Opening door #{id}"
    @doors[id].is_open = true
    @doors[id].a = 80.0
  end

  def current
    @@level_data[@idx - 1]
  end
end
