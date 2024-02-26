require 'gosu'

class Background
  def initialize
    @image = Gosu::Image.new("background.png", tileable: true)
    @width = @image.width
    @height = @image.height
    @x = 0
    @y = 0
  end

  def draw(camera_x, camera_y)
    @image.draw(@x - camera_x % @width, @y - camera_y % @height, 0, 1, 1, Gosu::Color::WHITE)
    @image.draw(@x - camera_x % @width + @width, @y - camera_y % @height, 0, 1, 1, Gosu::Color::WHITE)
    @image.draw(@x - camera_x % @width, @y - camera_y % @height + @height, 0, 1, 1, Gosu::Color::WHITE)
    @image.draw(@x - camera_x % @width + @width, @y - camera_y % @height + @height, 0, 1, 1, Gosu::Color::WHITE)
  end
end

class Platform
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
  end

  def draw(camera_x, camera_y)
    # Рисуем платформу
    Gosu.draw_rect(@x - camera_x, @y - camera_y, @width, @height, Gosu::Color::GREEN)

    # Рисуем хитбокс
    Gosu.draw_rect(@x - camera_x, @y - camera_y, @width, @height, Gosu::Color::BLUE, 999)
  end

  def hitbox
    { x: @x, y: @y, width: @width, height: @height }
  end
end

class Player
  attr_reader :x, :y, :width, :height, :jumping

  def initialize
    @x = 50
    @y = 1080 - 10
    @width = 50
    @height = 50
    @vel_x = 0
    @vel_y = 0
    @jumping = false
    @image = Gosu::Image.new("player.png")
  end

  def draw(camera_x)
    @image.draw(@x - camera_x, @y, 1)
    draw_hitbox(camera_x)
  end

  def draw_hitbox(camera_x)
    hitbox = { x: @x + 10 - camera_x, y: @y + 10, width: @width - 20, height: @height - 10 }
    Gosu.draw_rect(hitbox[:x], hitbox[:y], hitbox[:width], hitbox[:height], Gosu::Color::BLUE, 999)
  end

  def move_left
    @vel_x = -5
  end

  def move_right
    @vel_x = 5
  end

  def jump
    unless @jumping
      @vel_y = -10
      @jumping = true
    end
  end

  def update(platforms)
    @x += @vel_x
    @y += @vel_y
    @vel_x = 0
    if @y < 480 - @image.height
      @vel_y += 0.5
    else
      @vel_y = 0
      @jumping = false
      @y = 480 - @image.height
    end

    platforms.each do |platform|
      if collides_with?(platform.hitbox)
        if @vel_y > 0
          @y = platform.y - @height
          @jumping = false
          @vel_y = 0
        elsif @vel_y < 0
          @y = platform.y + platform.height
          @vel_y = 0
        end
      end
    end
  end

  def collides_with?(object)
    player_hitbox = { x: @x + 10, y: @y + 10, width: @width - 20, height: @height - 10 }
    player_hitbox[:x] < object[:x] + object[:width] &&
      player_hitbox[:x] + player_hitbox[:width] > object[:x] &&
      player_hitbox[:y] < object[:y] + object[:height] &&
      player_hitbox[:y] + player_hitbox[:height] > object[:y]
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(1920, 1080, false)
    self.caption = "My Platformer Game"
    @background = Background.new
    @player = Player.new
    @camera_x = 0
    @camera_y = -1000  # Поднимаем камеру на 1000 пикселей
    @platforms = [
      Platform.new(960, 0, 640, 20),  # Платформа на всю ширину экрана, внизу
      Platform.new(300, 0, 200, 20),        # Первая платформа выше
      Platform.new(1200, 0, 300, 20)        # Вторая платформа еще выше
    ]
  end

  def update
    @player.move_left if Gosu.button_down? Gosu::KB_LEFT
    @player.move_right if Gosu.button_down? Gosu::KB_RIGHT
    @player.jump if Gosu.button_down? Gosu::KB_SPACE
    @player.update(@platforms)

    # Перемещаем камеру только по горизонтали, если персонаж находится в определенной части экрана
    if @player.x > 320 && @player.x < 1280
      @camera_x = @player.x - 320
    elsif @player.x >= 1280
      @camera_x = 1920 - 640
    else
      @camera_x = 0
    end
  end

  def draw
    @background.draw(@camera_x, @camera_y)
    @player.draw(@camera_x)
    @platforms.each { |platform| platform.draw(@camera_x, @camera_y) }
  end
end

window = GameWindow.new
window.show
