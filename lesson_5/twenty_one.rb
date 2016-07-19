class Deck

end

class Card

end

class Participant

end

class Player < Participant

end

class Dealer < Participant

end

class Game
  def start
    puts "Welcome to Twenty-One!"
  end
end

Game.new.start
