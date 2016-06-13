class GoodDog
  attr_accessor :name, :height, :weight
  def initialize(n, h, w)
    @name = n
    @height = h
    @weight = w
  end

  def speak
    "#{name} says arf!"
  end

  def change_info(n, h, w)
    self.name = n
    self.height = h
    self.weight = w
  end
end

sparky = GoodDog.new('Sparky', '2', '20')
puts sparky.name
puts sparky.speak
sparky.change_info('Spartacus', '2.5', '30' )
p sparky
