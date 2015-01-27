require_relative 'game/game.rb'

player_id = "jevanwu@gmail.com"

game = Game.new(player_id)
game.start
game.number_of_words.times do |_num|
  game.new_word
  game.start_guess
  game.print_result
end

puts "Do you want to submit the result? (YES/NO)"
submit_result = STDIN.gets.strip
case submit_result
when "YES"
  game.submit_result 
  exit
else
  exit
end
