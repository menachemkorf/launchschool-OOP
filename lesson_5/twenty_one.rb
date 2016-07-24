require 'pry'

class Deck

  SUITS = ['H', 'D', 'S', 'C']
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  SETS = SUITS.product(FACES)

  attr_accessor :cards

  def initialize
    @cards = []
    SETS.each { |set| @cards << Card.new(*set) }
    @cards.shuffle!
  end

  def deal(participant, number=1)
    number.times do
      participant.cards << cards.pop
    end
  end

  def to_s
    cards
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
  attr_accessor :cards, :choice

  def initialize
    # cards, name
    @cards = []
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
end

class Player < Participant

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

  attr_accessor :deck, :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    deal_cards
    display_initial_cards
    player_turn
    dealer_turn unless player.busted?
    display_all_cards
    display_result
  end

  private

  def deal_cards
    deck.deal(player, 2)
    deck.deal(dealer, 2)
  end

  def display_initial_cards
    clear
    puts "Player has [#{player.show_all_cards}]. For a total of #{player.total}"
    puts "Dealer has [#{dealer.show_first_card}] and ?"
  end

  def player_turn
    loop do
      player.choose
      if player.hit?
        deck.deal(player)
        display_initial_cards
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

  def display_all_cards
    puts "Player has [#{player.show_all_cards}]. For a total of #{player.total}"
    puts "Dealer has [#{dealer.show_all_cards}]. For a total of #{dealer.total}"
  end

  def display_result
    if player.busted?
      puts "Player busted!"
    elsif dealer.busted?
      puts "Dealer busted!."
    elsif player.total > dealer.total
      puts "Player won!"
    elsif dealer.total > player.total
      puts "Dealer won!"
    else
      puts "It's a tie!"
    end
  end
end

Game.new.start
