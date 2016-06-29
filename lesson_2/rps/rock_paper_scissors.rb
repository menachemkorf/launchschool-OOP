# frozen_string_literal: true
require 'pry'

class History
  attr_accessor :logs

  def initialize
    self.logs = []
    reset
  end

  def move_with_most_loses
    lost = filter_rounds(:computer)
    count_lost = count_rounds(lost)
    max = count_lost.max_by { |_move, loses| loses }
    max[0] if max
  end

  def lost?
    !filter_rounds(:computer).empty?
  end

  def current_game_logs
    logs.last
  end

  def add(log)
    logs.last << log
  end

  def last_round
    logs.flatten.last
  end

  def reset
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

  def self.valid?(choice)
    VALUES.flatten.include?(choice)
  end

  def self.format(choice)
    choice = VALUES[choice] if VALUES.keys.include?(choice)
    choice
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
  end

  def to_s
    name
  end
end

class Human < Player
  def choose
    choice = nil
    loop do
      prompt_move
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

  def prompt_move
    puts ""
    puts "Please choose one:"
    Move::VALUES.each do |initial, value|
      puts "#{initial}. #{value}"
    end
    puts ""
  end
end

class Computer < Player
  def choose(history)
    # if human didn't lose yet move_with_most_loses will return nil
    lost_move = nil
    if history.lost?
      last_round = history.last_round
      lost_move = if last_round[:winner] == :computer
                    last_round[:human_move]
                  else
                    history.move_with_most_loses
                  end
    end
    self.move = Move.new(filter_moves(lost_move).sample)
  end

  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def filter_moves(lost_move = nil)
    # the computer assumes that human won't use lost_move
    # so we reject any move that can beat lost_move to increase the computer's
    # probability of winning
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
    puts "#{human} chose #{human.move}"
    puts "#{computer} chose #{computer.move}"
  end

  def display_round(winner)
    puts winner ? "#{winner} won!" : "It's a tie!"
    puts "#{human} = #{human.score}"
    puts "#{computer} = #{computer.score}"
  end

  def display_winner
    puts ""
    if human.score == points_to_win
      puts "#{human} won the game!"
    else
      puts "#{computer} won the game!"
    end
  end

  def display_summary
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
      reset_score
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

  def reset_score
    human.score = 0
    computer.score = 0
    history.reset
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
