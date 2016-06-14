module Towable
  def can_tow?(pounds)
    pounds < 2000 ? true : false
  end
end

class Vehicle
  attr_accessor :color
  attr_reader :year

  @@number_of_vehicles = 0

  def initialize(year, model, color)
    @year = year
    @model = model
    @color = color
    @current_speed = 0
    @@number_of_vehicles += 1
  end

  def speed_up(number)
    @current_speed += number
    puts "You push the gas and accelerate #{number} mph."
  end

  def brake(number)
    @current_speed -= number
    puts "You push the brake and decelerate #{number} mph."
  end

  def current_speed
    puts "You are now going #{@current_speed} mph."
  end

  def shut_down
    @current_speed = 0
    puts "Let's park this bad boy!"
  end

  def spray_paint(color)
    @color = color
    puts "You new #{color} paint job looks great!"
  end

  def age
    puts "Your car is #{years_old} years old."
  end

  def self.gas_mileage(gallons, miles)
    puts "#{miles / gallons} miles per gallon of gas."
  end

  def self.number_of_vehicles
    puts "#{@@number_of_vehicles} vehicles were instantiated"
  end

  private
    def years_old
      Time.now.year - @year
    end

end

class MyCar < Vehicle

  NUMBER_OF_DOORS = 4

  def to_s
    puts "MyCar is a #{@color}, #{@year}, #{@model}!"
  end

end

class MyTruck < Vehicle

  include Towable

  NUMBER_OF_DOORS = 2

  def to_s
    puts "MyTruck is a #{@color}, #{@year}, #{@model}!"
  end

end

lumina = MyCar.new(1997, 'chevy lumina', 'white')
colorado = MyTruck.new(2015, 'chevy colorado', 'red')
# Vehicle.number_of_vehicles
# puts MyCar.ancestors
# puts ""
# puts MyTruck.ancestors
# puts ""
# puts Vehicle.ancestors
# lumina.age
# colorado.age
