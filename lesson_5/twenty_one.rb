require 'pry'

class Deck

  SUITS = ['H', 'D', 'S', 'C']
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  SETS = SUITS.product(FACES)

  attr_accessor :cards

  def initialize
    reset
  end

  def deal(participant, number=1)
    number.times do
      participant.cards << cards.pop
    end
  end

  def to_s
    cards
  end

  def reset
    @cards = []
    SETS.each { |set| @cards << Card.new(*set) }
    @cards.shuffle!
  end
end

class Card
  attr_accessor :suit, :face, :value

  def initialize(suit, face)
    @suit = suit
    @face = face
    @value = { suit: suit, face: face }
  end

  def to_s
    value.to_s
  end

  def suit_symbols
    {'H' => '♥', 'D' => '♦', 'S' => '♠', 'C' => '♣'}
  end
end

class Participant
  attr_accessor :cards, :choice, :name, :score

  def initialize
    set_name
    reset
  end

  def reset
    reset_round
    self.score = 0
  end

  def reset_round
    @cards = []
  end

  def increment_score
    self.score += 1
  end

  def show_all_cards
    visible_cards = []
    cards.each do |card|
      visible_cards << "#{card.face} of #{card.suit}"
    end
    visible_cards.join(', ')
  end

  def show_first_card
    first_card = cards.first
    "#{first_card.face} of #{first_card.suit}"
  end

  def hit?
    self.choice == 'h'
  end

  def stay?
    self.choice == 's'
  end

  def total
    # needs refactoring
    values = cards.map { |card| card.face }
    sum = 0

    values.each do |value|
      sum += if value == "A"
             11
           elsif value.to_i == 0
             10
           else
             value.to_i
           end
    end

    values.select { |value| value == "A" }.count.times do
      sum -= 10 if sum > 21
    end
    sum
  end

  def busted?
    total > 21
  end

  def to_s
    name
  end

  def declare_busted
    puts "#{self} busted!"
  end

  def declare_won_round
    puts "#{self} won!"
  end

  def declare_won_game
    puts "#{self} won the game!"
  end
end

class Player < Participant
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

  def choose
    answer = nil
    loop do
      puts "(h)it or (s)tay"
      answer = gets.chomp.downcase
      break if %w(h s).include?(answer)
      puts "Invalid option!"
    end
    self.choice = answer
  end
end

class Dealer < Participant
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

class Game
  include ScreenHelper

  attr_accessor :deck, :player, :dealer, :points_to_win, :result

  def initialize
    clear
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
    set_rounds
  end

  def start
    loop do
      play_game
      break unless play_again?
      reset_game
    end
  end

  private

  def play_game
    loop do
      deal_cards
      display_cards(:partial)
      player_turn
      dealer_turn unless player.busted?
      detect_result
      update_score
      display_result
      break if game_over?
      reset_round
    end
    display_game_winner
  end

  def set_rounds
    loop do
      puts "Hi #{player}. How many points do you want to play for?"
      self.points_to_win = gets.chomp.to_i
      break if points_to_win > 0
      puts "Invalid option!"
    end
    puts "Ok, so whoever gets #{points_to_win} points first wins."
    pause
  end

  def reset_game
    deck.reset
    player.reset
    dealer.reset
  end

  def reset_round
    deck.reset
    player.reset_round
    dealer.reset_round
  end

  def display_game_winner
    game_winner.declare_won_game
  end

  def game_winner
    [player, dealer].find { |player| player.score == points_to_win }
  end

  def game_over?
    !!game_winner
  end

  def deal_cards
    deck.deal(player, 2)
    deck.deal(dealer, 2)
  end

  def display_cards(options)
    clear
    puts "#{player} has #{player.score} points. #{dealer} has #{dealer.score} points."
    puts "#{player} has [#{player.show_all_cards}]. For a total of #{player.total}"

    if options == :partial
      puts "#{dealer} has [#{dealer.show_first_card}] and ?"
    else
      puts "#{dealer} has [#{dealer.show_all_cards}]. For a total of #{dealer.total}"
    end
  end

  def player_turn
    loop do
      player.choose
      if player.hit?
        deck.deal(player)
        display_cards(:partial)
      end
      break if player.stay? || player.busted?
    end
  end

  def dealer_turn
    puts "Dealer's choosing..."
    until dealer.total >= 17 do
      deck.deal(dealer)
    end
  end

  def detect_result
    self.result = if player.busted? # || (dealer.total > player.total)
                    :player_busted
                  elsif dealer.busted? # || (player.total > dealer.total)
                    :dealer_busted
                  elsif player.total > dealer.total
                    :player_won
                  elsif dealer.total > player.total
                    :dealer_won
                  else
                    :tie
                  end
  end

  def update_score
    case result
    when :player_busted, :dealer_won
      dealer.increment_score
    when :dealer_busted, :player_won
      player.increment_score
    end
  end

  def display_result
    display_cards(:full)

    case result
    when :player_busted
      player.declare_busted
      dealer.declare_won_round
    when :dealer_busted
      dealer.declare_busted
      player.declare_won_round
    when :player_won
      player.declare_won_round
    when :dealer_won
      dealer.declare_won_round
    else
      declare_tie
    end
    pause
  end

  def declare_tie
    puts "It's a tie!"
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
end

Game.new.start
