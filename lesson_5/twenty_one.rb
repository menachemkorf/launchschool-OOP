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

  def deal

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
end

class Participant
  def initialize
    # cards, name
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
  def initialize
    @deck = Deck.new
    puts @deck.cards
  end

  def start

    # deal_cards
    # show_initial_cards
    # player_turn
    # dealer_turn
    # show_result
  end

  private

end

Game.new.start
