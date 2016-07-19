# frozen_string_literal: true
class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  def []=(key, marker)
    squares[key].marker = marker
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def pick_square_offensively
    pick_square(:computer)
  end

  def pick_square_defensively
    pick_square(:human)
  end

  def pick_center_square
    unmarked_keys.find { |sqr| sqr == 5 }
  end

  def pick_random_square
    unmarked_keys.sample
  end

  def winning_marker
    WINNING_LINES.each do |line|
      sqrs = squares.values_at(*line)
      if three_identical_markers?(sqrs)
        return sqrs.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| squares[key] = Square.new }
  end

  private

  def pick_square(player)
    WINNING_LINES.each do |line|
      sqrs = squares.values_at(*line)
      if count_marked(sqrs, player) == 2 &&
         count_unmarked(sqrs) == 1
        return unmarked_square(line)
      end
    end
    nil
  end

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.max == markers.min
  end

  def count_marked(squares, player)
    case player
    when :computer
      squares.count(&:marked_computer?)
    when :human
      squares.count(&:marked_human?)
    end
  end

  def count_unmarked(squares)
    squares.count(&:unmarked?)
  end

  def unmarked_square(line)
    squares.find do |key, square|
      line.include?(key) && square.unmarked?
    end.first
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def marked_human?
    marker == TTTgame::HUMAN_MARKER
  end

  def marked_computer?
    marker == TTTgame::COMPUTER_MARKER
  end
end

class Player
  attr_reader :score, :marker
  attr_accessor :name

  def initialize(marker)
    @marker = marker
    set_name
    reset
  end

  def increment_score
    self.score += 1
  end

  def reset
    self.score = 0
  end

  def declare_win_round
    puts "#{self} won!"
  end

  def declare_win_game
    puts "#{self} won the game!"
  end

  def to_s
    name
  end

  private

  attr_writer :score
end

class Human < Player
  private

  def set_name
    n = nil
    loop do
      puts "What's your name?"
      n = gets.chomp.strip
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end
end

class Computer < Player
  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end
end

module ScreenHelper
  def clear
    system('clear') || system('cls')
  end

  def pause
    puts "Press enter to continue."
    gets
  end
end

module Displayable
  def display_welcome_message
    clear
    puts "Welcome to Tic Tac Toe!"
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def display_goodbye_message
    puts "Thank you for playing Tic Tac Toe! Good bye!"
  end

  def display_board
    display_markers
    display_score
    puts ""
    board.draw
    puts ""
  end

  def display_markers
    puts "#{human} is #{human.marker}. #{computer} is #{computer.marker}."
  end

  def display_score
    puts "#{human} has #{human.score} points. "\
         "#{computer} has #{computer.score} points."
  end

  def display_game_winner
    game_winner.declare_win_game
  end

  def display_result
    clear_screen_and_display_board
    case result
    when :human
      human.declare_win_round
    when :computer
      computer.declare_win_round
    else
      declare_tie
    end
    pause
  end

  def declare_tie
    puts "It's a tie!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end
end

class TTTgame
  include ScreenHelper
  include Displayable

  HUMAN_MARKER = "X"
  COMPUTER_MARKER = "O"
  FIRST_TO_MOVE = HUMAN_MARKER

  def initialize
    display_welcome_message
    @board = Board.new
    @human = Human.new(HUMAN_MARKER)
    @computer = Computer.new(COMPUTER_MARKER)
    @current_marker = FIRST_TO_MOVE
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def play
    set_rounds
    loop do
      loop do
        display_board
        loop do
          current_player_moves
          break if board.someone_won? || board.full?
          clear_screen_and_display_board if human_turn?
        end
        detect_result
        update_score
        display_result
        break if game_over?
        reset_round
      end
      display_game_winner
      break unless play_again?
      reset_game
    end
    display_goodbye_message
  end
  # rubocop:enable Metrics/AbcSize Metrics/MethodLength

  private

  attr_reader :human, :computer
  attr_accessor :board, :result, :points_to_win, :current_marker

  def set_rounds
    loop do
      puts "Hi #{human}. How many points do you want to play for?"
      self.points_to_win = gets.chomp.to_i
      break if points_to_win > 0
      puts "Invalid option!"
    end
    puts "Ok, so whoever gets #{points_to_win} points first wins."
    pause
  end

  def human_moves
    puts "Choose an empty square. (#{board.unmarked_keys.join(', ')}):"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Invalid option!"
    end
    board[square] = human.marker
  end

  def computer_moves
    square =  board.pick_square_offensively ||
              board.pick_square_defensively ||
              board.pick_center_square ||
              board.pick_random_square

    board[square] = computer.marker
  end

  def detect_result
    self.result = case board.winning_marker
                  when human.marker
                    :human
                  when computer.marker
                    :computer
                  else
                    :tie
                  end
  end

  def update_score
    case result
    when :human
      human.increment_score
    when :computer
      computer.increment_score
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %(y n).include?(answer)
      puts "Invalid option!"
    end
    answer == 'y'
  end

  def reset_round
    board.reset
    self.current_marker = FIRST_TO_MOVE
    clear
  end

  def reset_game
    reset_round
    reset_points
    display_play_again_message
  end

  def reset_points
    human.reset
    computer.reset
  end

  def current_player_moves
    if human_turn?
      human_moves
      self.current_marker = COMPUTER_MARKER
    else
      computer_moves
      self.current_marker = HUMAN_MARKER
    end
  end

  def human_turn?
    current_marker == HUMAN_MARKER
  end

  def game_winner
    [human, computer].find { |player| player.score == points_to_win }
  end

  def game_over?
    !!game_winner
  end
end

TTTgame.new.play
