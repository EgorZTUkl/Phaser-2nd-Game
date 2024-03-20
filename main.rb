require 'gosu'

class Platform
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x, @y, @width, @height = x, y, width, height
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::GREEN)
  end
end

class Player
  attr_reader :x, :y, :width, :height, :lives

  def initialize
    @x, @y, @width, @height = 320, 240, 32, 48
    @vel_x, @vel_y = 0, 0
    @jumping, @jump_power, @gravity = false, -20, 1
    @lives = 3
  end

  def move_left; @vel_x = -10; end
  def move_right; @vel_x = 10; end
  def stop; @vel_x = 0; end
  def jump; @vel_y = @jump_power unless @jumping; @jumping = true; end

  def apply_gravity; @vel_y += @gravity; end

  def update(platforms)
    @x += @vel_x; @y += @vel_y

    platforms.each do |platform|
      if @x + @width > platform.x && @x < platform.x + platform.width &&
         @y + @height > platform.y && @y < platform.y + platform.height
        @vel_y = 0; @jumping = false; @y = platform.y - @height
      end
    end

    @vel_x = 0 if @x < 0 || @x + @width > 1920
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::BLUE)
  end
end

class Bomb
  attr_reader :x, :y, :width, :height, :vel_y

  def initialize(x, y)
    @x, @y, @width, @height = x, y, 20, 20
    @vel_y = rand(2..5)
    @gravity = 1
  end

  def update(platforms)
    @y += @vel_y
    @vel_y += @gravity
    @vel_y *= -1 if @y > 1080
    platforms.each { |platform| bounce_off_platform(platform) }
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::RED)
  end

  private

  def bounce_off_platform(platform)
    if @x + @width > platform.x && @x < platform.x + platform.width &&
       @y + @height > platform.y && @y < platform.y + platform.height
      @vel_y *= -1
      @y = platform.y - @height
    end
  end
end

class Enemy
  attr_reader :x, :y, :width, :height

  def initialize
    @x, @y, @width, @height = rand(1920), rand(1080), 30, 30
    @vel_x, @vel_y = rand(-3..3), rand(-3..3)
  end

  def update
    @x += @vel_x
    @y += @vel_y
    @vel_x *= -1 if @x < 0 || @x + @width > 1920
    @vel_y *= -1 if @y < 0 || @y + @height > 1080
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::RED)
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(1920, 1080, false)
    self.caption = 'Simple Platformer'

    @player = Player.new
    @platforms = []
    generate_platforms

    @bombs = Array.new(5) { Bomb.new(rand(1920), rand(1080)) }
    @enemies = Array.new(3) { Enemy.new }
    @font = Gosu::Font.new(20)

    @camera_x = 0
  end

  def update
    update_player_movement
    @player.apply_gravity
    @player.update(@platforms)
    update_bombs
    update_enemies
    check_collisions
    check_game_over

    @camera_x += 5
  end

  def draw
    Gosu.translate(-@camera_x, 0) do
      @player.draw
      @platforms.each(&:draw)
      @bombs.each(&:draw)
      @enemies.each(&:draw)
    end

    @font.draw("Lives: #{@player.lives}", 10, 10, 1)
  end

  private

  def generate_platforms
    last_x = 0
    while last_x < 5000
      width = rand(100..300)
      height = rand(20..100)
      @platforms << Platform.new(last_x, 1000 - height, width, height)
      last_x += width + rand(50..200)
    end
  end

  def update_player_movement
    @player.stop
    @player.move_left if button_down?(Gosu::KB_LEFT)
    @player.move_right if button_down?(Gosu::KB_RIGHT)
    @player.jump if button_down?(Gosu::KB_SPACE)
  end

  def update_bombs
    @bombs.each { |bomb| bomb.update(@platforms) }
  end

  def update_enemies
    @enemies.each(&:update)
  end

  def check_collisions
  @bombs.each do |bomb|
    if bomb.x < @player.x + @player.width && bomb.x + bomb.width > @player.x &&
       bomb.y < @player.y + @player.height && bomb.y + bomb.height > @player.y
      @player.lives -= 1
      bomb.reset(rand(1920), rand(1080))
      close_game if @player.lives <= 0
    end
  end

  @enemies.each do |enemy|
    if enemy.x < @player.x + @player.width && enemy.x + enemy.width > @player.x &&
       enemy.y < @player.y + @player.height && enemy.y + enemy.height > @player.y
      @player.lives -= 1
      enemy.reset_position
      close_game if @player.lives <= 0
    end
  end
end

def close_game
  puts 'Game Over'
  close
  exit
end

  def check_game_over
     if @player.lives <= 0
       close
       puts 'Game Over'
       exit
     end
   end
 end

 window = GameWindow.new
 window.show
