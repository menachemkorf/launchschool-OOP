# frozen_string_literal: true
class Deck
  SUITS = ['♥', '♦', '♠', '♣'].freeze
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10',
           'J', 'Q', 'K', 'A'].freeze
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

  def reset
    @cards = []
    SETS.each { |set| @cards << Card.new(*set) }
    @cards.shuffle!
  end
end

class Card
  attr_accessor :suit, :face

  def initialize(suit, face)
    @suit = suit
    @face = face
  end

  def self.face_down
    ["+------+",
     "|?     |",
     "|      |",
     "|      |",
     "|     ?|",
     "+------+"]
  end

  def image
    ["+------+",
     "|#{format(face, :left)}    |",
     "|#{suit}     |",
     "|     #{suit}|",
     "|    #{format(face, :right)}|",
     "+------+"]
  end

  def format(str, position)
    if str.length == 2
      str
    else
      position == :left ? "#{str} " : " #{str}"
    end
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
    card_images = [*cards.map(&:image)]
    draw(card_images)
  end

  def show_first_card
    card_images = [cards.first.image, Card.face_down]
    draw(card_images)
  end

  def draw(card_images)
    card_images.transpose.each do |line|
      puts line.join(" ")
    end
  end

  def hit?
    choice == 'h'
  end

  def stay?
    choice == 's'
  end

  def total
    values = cards.map(&:face)
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
      sum -= 10 if sum > Game::HIGHEST_NUMBER
    end
    sum
  end

  def busted?
    total > Game::HIGHEST_NUMBER
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
      puts "(h)it or (s)tay?"
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

module Displayable
  def display_welcome_message
    clear
    puts "Welcome to Twenty-One!"
  end

  def display_goodbye_message
    puts "Thank you for playing Twenty-One! Good bye!"
  end

  def display_game_winner
    game_winner.declare_won_game
  end

  def display_cards(options)
    clear
    display_score
    puts ""
    display_player_cards
    puts ""
    display_dealer_cards(options)
    puts ""
  end

  def display_score
    puts "#{player} has #{player.score} points. "\
         "#{dealer} has #{dealer.score} points."
  end

  def display_player_cards
    puts "#{player}'s cards:"
    player.show_all_cards
    puts "Total = #{player.total}"
  end

  def display_dealer_cards(options)
    puts "#{dealer}'s cards:"
    if options == :partial
      dealer.show_first_card
    else
      dealer.show_all_cards
      puts "Total = #{dealer.total}"
    end
  end

  def display_result
    display_cards(:full)
    display_busted
    display_round_winner
    pause
  end

  def display_busted
    case result
    when :player_busted
      player.declare_busted
    when :dealer_busted
      dealer.declare_busted
    end
  end

  def display_round_winner
    case result
    when :player_won, :dealer_busted
      player.declare_won_round
    when :dealer_won, :player_busted
      dealer.declare_won_round
    else
      declare_tie
    end
  end

  def declare_tie
    puts "It's a tie!"
  end
end

class Game
  include ScreenHelper
  include Displayable

  DEALER_STAYS = 17
  HIGHEST_NUMBER = 21

  attr_accessor :deck, :player, :dealer, :points_to_win, :result

  def initialize
    display_welcome_message
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
    display_goodbye_message
  end

  private

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

  def play_game
    loop do
      play_round
      break if game_over?
      reset_round
    end
    display_game_winner
  end

  def play_round
    deal_cards
    display_cards(:partial)
    player_turn
    dealer_turn unless player.busted?
    detect_result
    update_score
    display_result
  end

  def deal_cards
    deck.deal(player, 2)
    deck.deal(dealer, 2)
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
    deck.deal(dealer) until dealer.total >= DEALER_STAYS
  end

  def detect_result
    self.result = if player.busted?
                    :player_busted
                  elsif dealer.busted?
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

  def game_winner
    [player, dealer].find { |player| player.score == points_to_win }
  end

  def game_over?
    !!game_winner
  end

  def reset_round
    deck.reset
    player.reset_round
    dealer.reset_round
  end

  def reset_game
    deck.reset
    player.reset
    dealer.reset
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
