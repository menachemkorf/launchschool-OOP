# frozen_string_literal: true
require 'pry'

class History
  attr_accessor :logs

  def initialize
    # log is an array of arrays
    # [[player_move, computer_move, :winner],[...]]
    # with :winner being either :human, :computer, :tie
    self.logs = []
  end

  def move_with_most_loses
    # get all the logs where human lost
    lost = logs.select do |log|
      log[2] == :computer
    end

    # make new hash with amount of times lost with each move. {move => int}
    lost_count = Hash.new(0)
    lost.each do |move|
      lost_count[move[0]] += 1
    end

    max = lost_count.max_by { |_move, loses| loses }
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
end

class Player
  attr_accessor :move, :name, :score, :player_history

  def initialize
    set_name
    self.score = 0
    @player_history = []
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
    @player_history << move
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
  def choose(history)
    # if human didn't lose yet move_with_most_loses will return nil
    lost_move = nil
    if history.move_with_most_loses
      last_round = history.logs.last
      lost_move = if last_round[2] == :computer
                    last_round[0]
                  else
                    history.move_with_most_loses
                  end
    end
    self.move = Move.new(filter_moves(lost_move).sample)
    @player_history << move
  end

  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def filter_moves(lost_move = nil)
    # the computer assumes that human won't use lost_move
    # so we reject any move that can beat lost_move to increase the computer's
    # probability of winning
    options = if lost_move
                Move::VALUES.values.reject do |move|
                  Move::LOOSING_MOVES[lost_move.value].include?(move)
                end
              else
                Move::VALUES.values
              end
    options
  end
end

module Display
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
    if human.score == points_to_win
      puts "#{human} won the game!"
    else
      puts "#{computer} won the game!"
    end
  end

  def display_summary
    puts "#{human.name[0, 8].center(10)} | #{computer.name.center(10)}"
    puts "+".center(23, '-')
    human.player_history.size.times do |i|
      puts "#{human.player_history[i].value.center(10)} | #{computer.player_history[i].value.center(10)}"
    end

    # combined_history = human.player_history.zip(computer.player_history)
    # combined_history.each do |x|

    #   if x[0] > x[1]
    #     x << :human
    #   elsif x[1] > x[0]
    #     x << :computer
    #   else
    #     x << :tie
    #   end
    # end
    # combined_history.each { |x| p x }
  end
end

class RPSGame
  include Display

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

    log = [human.move, computer.move, winner]
    history.logs << log
  end

  def reset_score
    human.score = 0
    human.player_history = []
    computer.score = 0
    computer.player_history = []
  end

  def game_over?
    human.score == points_to_win || computer.score == points_to_win
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Invalid option"
    end
    answer == 'y'
  end
end

RPSGame.new.play
