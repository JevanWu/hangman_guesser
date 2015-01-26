require 'rest-client'

class Guesser
  attr_accessor :player_id, :session_id 
  attr_reader :current_word, :guessed_chars

  def initialize(request_url)
    @request_url = request_url 
    @guessed_chars = []
  end

  def guess(char)
    puts "Guessing #{char} ..."
    @last_word = @current_word
    params = { 
               "sessionId" => session_id,
               "action" =>  "guessWord",
               "guess" => char
             }.to_json
    res = JSON.parse(RestClient.post(@request_url, params, :content_type => :json, :accept => :json))
    @guessed_chars << char
    @current_word = res["data"]["word"]
    puts "Current word: #{res["data"]["word"]}"
  end

  def finish_the_word?
    @current_word.match(/\*/) ? false : true
  end

  def hit_a_char?
    @current_word.count('*') < @last_word.count('*')
  end

  def get_new_word(word)
    @current_word = word
  end

  def clear_guessed_chars
    @guessed_chars = [] 
  end

end
