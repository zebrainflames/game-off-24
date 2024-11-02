require_relative 'sprite'

class Hero < Sprite
  attr_accessor :state, :dx, :dy

  def update(horizontal, vertical)
    state ||= :idle
    return unless horizontal or vertical

    @x += horizontal * 4.3
    @y += vertical * 4.3
    @dx = horizontal
    @dy = vertical
  end
end
