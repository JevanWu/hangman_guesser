require 'json'
require 'rest-client'
require 'pry'
require_relative 'guesser'
require_relative 'dictionary'

class Game

  REQUEST_URL = "https://strikingly-hangman.herokuapp.com/game/on"

  attr_reader :number_of_words, :number_to_guess

  def initialize(id)
    @guesser = Guesser.new(REQUEST_URL)
    @guesser.player_id = id
    Dictionary.init
  end

  def start
    params = { 
               "playerId" => @guesser.player_id,
               "action" => "startGame"
             }.to_json
    res = send_request(params) 
    @guesser.session_id = res["sessionId"]
    @number_of_words = res["data"]["numberOfWordsToGuess"]
    @number_to_guess = res["data"]["numberOfGuessAllowedForEachWord"]
    puts "The game is starting ..."
  end

  def get_new_word
    puts "Getting new word ..."
    params = { 
               "sessionId" => @guesser.session_id,
               "action" => "nextWord"
             }.to_json
    res = send_request(params)
    puts "New word: #{res["data"]["word"]}"
    @word_length = res["data"]["word"].length
    @guesser.get_new_word(res["data"]["word"])
  end

  def start_guess
    ['E', 'A', 'O', 'I', 'U', 'Y', 'S', 'T'].each do |char|
      @guesser.guess(char)
      break if @guesser.hit_a_char?
    end

    #skip word if still all *
    return if /\w/.match(@guesser.current_word).nil?

    loop do 
      # calculate the frequency of letters in missing position
      char_frequency = {} 
      filtered_words.each do |word|
        missing_position.each do |position|
          char = word[position]
          char_frequency[char] = 0 if char_frequency[char].nil?
          char_frequency[char] += 1
        end
      end

      #set the frequency of guessed letters to zero
      @guesser.guessed_chars.each{ |char| char_frequency[char] = 0 }

      sorted_fequency = char_frequency.sort_by{ |_k, v| -v }.to_h

      #guess most frequent letter
      @guesser.guess(sorted_fequency.first[0])

      break if @guesser.finish_the_word?

      #remove the words containing the guessed letter if not right
      @filtered_words.delete_if{ |word| word.include?(sorted_fequency.first[0]) } if !@guesser.hit_a_char?

      #skip
      break if @filtered_words.empty?
    end

    puts "Finish word: #{@guesser.current_word}" if @guesser.finish_the_word?

    #reset variables
    @filtered_words = nil
    @missing_position = nil
    @guesser.clear_guessed_chars
  end

  def print_result
    params = {
               "sessionId" => @guesser.session_id,
               "action" => "getResult"
             }.to_json
    res = send_request(params)
    puts "Total Word Count: #{res["data"]["totalWordCount"]}"
    puts "Currect Word Count: #{res["data"]["correctWordCount"]}"
    puts "Total Wrong Guess Count: #{res["data"]["totalWrongGuessCount"]}"
    puts "Score: #{res["data"]["score"]}"
  end

  def submit_result
    params = {
               "sessionId" => @guesser.session_id,
               "action" => "submitResult"
             }.to_json
    res = send_request(params)
  end

  private

    def filtered_words
      if @filtered_words.nil?
        @filtered_words = Dictionary.all_words.select { |word| word.length == @guesser.current_word.length }
      end
      word = @guesser.current_word.gsub("*", "\\w")
      regex = Regexp.new(word)
      @filtered_words = @filtered_words.select { |word| !regex.match(word).nil? }
    end

    def send_request(params)
      JSON.parse(RestClient.post(REQUEST_URL, params, :content_type => :json, :accept => :json))   
    end

    def missing_position
      return @missing_position unless @missing_position.nil?
      @missing_position = []
      offset = 0
      loop do 
        position = @guesser.current_word.index("*", offset)
        break if position.nil?
        offset = position + 1
        @missing_position << position
      end
      @missing_position
    end
end
