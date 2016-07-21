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
  attr_accessor :cards

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

  def hit

  end

  def stay

  end

  def busted?

  end

  def total

  end
end

class Player < Participant

end

class Dealer < Participant

end

class Game
  attr_accessor :deck, :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    deal_cards
    show_initial_cards
    # player_turn
    # dealer_turn
    # show_result
  end

  private

  def deal_cards
    deck.deal(player, 2)
    deck.deal(dealer, 2)
  end

  def show_initial_cards
    puts "Player has [#{player.show_all_cards}]"
    puts "Dealer has [#{dealer.show_first_card}] and ?"
  end
end

Game.new.start
