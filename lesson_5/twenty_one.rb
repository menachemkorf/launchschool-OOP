# frozen_string_literal: true
class Deck
  SUITS = ['♥', '♦', '♠', '♣'].freeze
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10',
           'J', 'Q', 'K', 'A'].freeze
  SETS = SUITS.product(FACES)

  attr_reader :cards

  def initialize
    reset
  end

  def deal(participant, number=1)
    number.times do
      participant.hand << cards.pop
    end
  end

  def reset
    self.cards = []
    SETS.each { |set| cards << Card.new(*set) }
    cards.shuffle!
  end

  private

  attr_writer :cards
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
     "|#{format_digits(face, :left)}    |",
     "|#{suit}     |",
     "|     #{suit}|",
     "|    #{format_digits(face, :right)}|",
     "+------+"]
  end

  private

  def format_digits(digits, position)
    if digits.length == 2
      digits
    else
      position == :left ? "#{digits} " : " #{digits}"
    end
  end
end

class Hand
  attr_reader :cards

  def initialize
    @cards = []
  end

  def <<(card)
    @cards << card
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

  def reset
    self.cards = []
  end

  def show_all_cards
    card_images = [*cards.map(&:image)]
    draw(card_images)
  end

  def show_first_card
    card_images = [cards.first.image, Card.face_down]
    draw(card_images)
  end

  private

  attr_writer :cards

  def draw(card_images)
    card_images.transpose.each do |line|
      puts line.join(" ")
    end
  end
end

class Participant
  attr_reader :score, :name, :hand

  def initialize
    set_name
    @hand = Hand.new
    reset
  end

  def increment_score
    self.score += 1
  end

  def reset
    hand.reset
    self.score = 0
  end

  def hit?
    choice == 'h'
  end

  def stay?
    choice == 's'
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

  private

  attr_writer :score, :name
  attr_accessor :choice
end

class Player < Participant
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

class Dealer < Participant
  private

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end
end

module ScreenHelper
  private

  def clear
    system('clear') || system('cls')
  end

  def pause
    puts "Press enter to continue."
    gets
  end
end

module Displayable
  private

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
    player.hand.show_all_cards
    puts "Total = #{player.hand.total}"
  end

  def display_dealer_cards(options)
    puts "#{dealer}'s cards:"
    if options == :partial
      dealer.hand.show_first_card
    else
      dealer.hand.show_all_cards
      puts "Total = #{dealer.hand.total}"
    end
  end

  def display_result
    display_cards(:full)
    display_busted
    display_round_winner
    pause
  end

  def display_busted
    case round_result
    when :player_busted
      player.declare_busted
    when :dealer_busted
      dealer.declare_busted
    end
  end

  def display_round_winner
    case round_result
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

  attr_accessor :points_to_win, :round_result
  attr_reader :deck, :player, :dealer

  def set_rounds
    loop do
      puts "Hi #{player}. How many rounds do you want to play for?"
      self.points_to_win = gets.chomp.to_i
      break if points_to_win > 0
      puts "Invalid option!"
    end
    puts "Ok, so whoever wins #{points_to_win} rounds first, wins the game."
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
    dealer_turn unless player.hand.busted?
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
      break if player.stay? || player.hand.busted?
    end
  end

  def dealer_turn
    deck.deal(dealer) until dealer.hand.total >= DEALER_STAYS
  end

  def detect_result
    self.round_result = if player.hand.busted?
                          :player_busted
                        elsif dealer.hand.busted?
                          :dealer_busted
                        elsif player.hand.total > dealer.hand.total
                          :player_won
                        elsif dealer.hand.total > player.hand.total
                          :dealer_won
                        else
                          :tie
                        end
  end

  def update_score
    case round_result
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
    player.hand.reset
    dealer.hand.reset
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
      break if %w(y n).include?(answer)
      puts "Invalid option!"
    end
    answer == 'y'
  end
end

Game.new.start
