# frozen_string_literal: true
require 'pry'

class History
  attr_accessor :logs

  def initialize
    self.logs = []
  end

  def lost_move
    if lost?
      if last_round[:winner] == :computer
        last_round[:human_move]
      else
        move_with_most_loses
      end
    end
  end

  def current_game_logs
    logs.last
  end

  def add(log)
    logs.last << log
  end

  def reset_round
    logs << []
  end

  private

  def filter_rounds(winner)
    logs.flatten.select do |log|
      log[:winner] == winner
    end
  end

  def count_rounds(rounds)
    count = Hash.new(0)
    rounds.each do |round|
      count[round[:human_move]] += 1
    end
    count
  end

  def lost?
    !filter_rounds(:computer).empty?
  end

  def last_round
    logs.flatten.last
  end

  def move_with_most_loses
    lost = filter_rounds(:computer)
    count_lost = count_rounds(lost)
    max = count_lost.max_by { |_move, loses| loses }
    max[0] if max
  end
end

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

  LOOSING_MOVES = { 'rock'     => %w(paper spock),
                    'paper'    => %w(scissors lizard),
                    'scissors' => %w(rock spock),
                    'lizard'   => %w(rock scissors),
                    'spock'    => %w(paper lizard) }.freeze

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

  def self.prompt
    puts ""
    puts "Please choose one:"
    VALUES.each do |initial, value|
      puts "#{initial}. #{value}"
    end
    puts ""
  end

  def self.valid?(choice)
    VALUES.flatten.include?(choice)
  end

  def self.format(choice)
    choice = VALUES[choice] if VALUES.keys.include?(choice)
    choice
  end
end

class Player
  attr_accessor :move, :name, :score

  def initialize
    set_name
  end

  def reset_round
    self.score = 0
  end

  def declare_move
    puts "#{name} chose #{move}"
  end

  def declare_score
    puts "#{name} = #{score}"
  end

  def declare_win_round
    puts "#{name} won!"
  end

  def declare_win_game
    puts "#{name} won the game!"
  end

  def to_s
    name
  end
end

class Human < Player
  def choose
    choice = nil
    loop do
      Move.prompt
      choice = gets.chomp.downcase

      if Move.valid?(choice)
        choice = Move.format(choice)
        break
      else
        puts "Invalid option!"
      end
    end

    self.move = Move.new(choice)
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
end

class Computer < Player
  def choose(history)
    self.move = Move.new(filter_moves(history.lost_move).sample)
  end

  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def filter_moves(lost_move = nil)
    # the computer assumes that human won't use lost_move
    # so we reject any move that can beat lost_move to increase the computer's
    # chances of winning
    if lost_move
      Move::VALUES.values.reject do |move|
        Move::LOOSING_MOVES[lost_move.value].include?(move)
      end
    else
      Move::VALUES.values
    end
  end
end

module Displayable
  private

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts "Thank you for playing Rock, Paper, Scissors. Good bye!"
  end

  def display_moves
    human.declare_move
    computer.declare_move
  end

  def display_round(winner)
    winner ? winner.declare_win_round : declare_tie
    human.declare_score
    computer.declare_score
  end

  def declare_tie
    puts "It's a tie!"
  end

  def display_winner
    winner = [human, computer].find { |player| player.score = points_to_win }
    puts ""
    winner.declare_win_game
  end

  def display_summary
    puts ""
    puts table_header
    puts "+".center(23, '-')
    summery = history.current_game_logs
    summery.each do |log|
      puts table_row(log)
    end
  end

  def table_header
    "#{format(human.name)} | #{format(computer.name)}"
  end

  def table_row(log)
    "#{format(log[:human_move].value)} | "\
    "#{format(log[:computer_move].value)}"
  end

  def format(output, length = 10, padding = " ")
    output[0, length - 2].center(length, padding)
  end
end

class RPSGame
  include Displayable

  attr_accessor :human, :computer, :points_to_win, :history

  def initialize
    @human = Human.new
    @computer = Computer.new
    @history = History.new
  end

  def play
    display_welcome_message
    set_rounds
    loop do
      reset_game
      loop do
        human.choose
        computer.choose(history)
        display_moves
        winner = detect_result
        update_score!(winner)
        display_round(winner)
        update_history!(winner)
        break if game_over?
      end
      display_winner
      display_summary
      break unless play_again?
    end
    display_goodbye_message
  end

  private

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

  def update_history!(winner)
    winner = case winner
             when human
               :human
             when computer
               :computer
             else
               :tie
             end

    log = { human_move: human.move,
            computer_move: computer.move,
            winner: winner }
    history.add(log)
  end

  def reset_game
    human.reset_round
    computer.reset_round
    history.reset_round
  end

  def game_over?
    human.score == points_to_win || computer.score == points_to_win
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if ['y', 'n'].include? answer
      puts "Invalid option!"
    end
    answer == 'y'
  end
end

RPSGame.new.play
