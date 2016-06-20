# frozen_string_literal: true
class Move
  VALUES = { 'r' => 'rock',
             'p' => 'paper',
             's' => 'scissors',
             'l' => 'lizard',
             'sp' => 'spock' }.freeze
  WINNING_MOVES = { 'rock'     => %w(scissors lizard),
                    'paper'    => %w(rock spock),
                    'scissors' => %w(paper lizard),
                    'lizard'   => %w(paper spock),
                    'spock'    => %w(rock scissors) }.freeze
  attr_accessor :value

  def initialize(value)
    self.value = value
  end

  def >(other_move)
    WINNING_MOVES[value].include?(other_move.value)
  end

  def to_s
    value
  end
end

class Player
  attr_accessor :move, :name, :score

  def initialize
    set_name
    self.score = 0
    @history = []
  end

  def to_s
    name
  end
end

class Human < Player
  def choose
    choice = nil
    loop do
      prompt_choice
      choice = gets.chomp

      if valid?(choice)
        choice = formatted(choice)
        break
      else
        puts "Invalid option!"
      end
    end

    self.move = Move.new(choice)
    @history << move.value
  end

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

  def prompt_choice
    puts "Please choose one:"
    Move::VALUES.each do |initial, value|
      puts "#{initial}. #{value}"
    end
  end

  def valid?(choice)
    Move::VALUES.flatten.include?(choice)
  end

  def formatted(choice)
    choice = Move::VALUES[choice] if Move::VALUES.keys.include?(choice)
    choice
  end
end

class Computer < Player
  def choose
    self.move = Move.new(Move::VALUES.values.sample)
    @history << move.value
  end

  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end
end

class RPSGame
  attr_accessor :human, :computer, :points_to_win

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def play
    display_welcome_message
    set_rounds
    loop do
      loop do
        human.choose
        computer.choose
        display_moves
        winner = detect_result
        update_score!(winner)
        display_round(winner)
        break if game_over?
      end
      display_winner
      break unless play_again?
    end
    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts "Thank you for playing Rock, Paper, Scissors. Good bye!"
  end

  def display_moves
    puts "#{human} chose #{human.move}"
    puts "#{computer} chose #{computer.move}"
  end

  def set_rounds
    loop do
      puts "How many points do you want to play for?"
      self.points_to_win = gets.chomp.to_i
      break if points_to_win > 0
      puts "Invalid option!"
    end
    puts "Ok, so whoever gets #{points_to_win} points first wins."
  end

  def detect_result
    if human.move > computer.move
      human
    elsif computer.move > human.move
      computer
    end
  end

  def update_score!(winner)
    winner.score += 1 if winner
  end

  def display_round(winner)
    puts winner ? "#{winner} won!" : "It's a tie!"
    puts "#{human} = #{human.score}"
    puts "#{computer} = #{computer.score}"
  end

  def game_over?
    human.score == points_to_win || computer.score == points_to_win
  end

  def display_winner
    if human.score == points_to_win
      puts "#{human} won the game!"
    else
      puts "#{computer} won the game!"
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Invalid option"
    end
    answer == 'y' ? true : false
  end
end

RPSGame.new.play
