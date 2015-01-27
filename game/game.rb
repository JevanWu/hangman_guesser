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
    res = get_responce(params) 
    @guesser.session_id = res["sessionId"]
    @number_of_words = res["data"]["numberOfWordsToGuess"]
    @number_to_guess = res["data"]["numberOfGuessAllowedForEachWord"]
    puts "The game is starting ..."
  end

  def new_word
    puts "Getting new word ..."

    reset_variable

    params = { 
               "sessionId" => @guesser.session_id,
               "action" => "nextWord"
             }.to_json

    res = get_responce(params)
    puts "New word: #{res["data"]["word"]}"

    @word_length = res["data"]["word"].length
    @guesser.get_new_word(res["data"]["word"])
  end

  def start_guess

    guess_most_frequent_vowel

    loop do 
      break unless guessing_most_frequent_letter?

      #skip the word if no filtered words any more
      break if filtered_words.empty?

      break if @guesser.finish_the_word?
    end

    puts "Finish word: #{@guesser.current_word}" if @guesser.finish_the_word?
  end

  def print_result
    params = {
               "sessionId" => @guesser.session_id,
               "action" => "getResult"
             }.to_json
    res = get_responce(params)

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
    res = get_responce(params)

    puts "Score: #{res["data"]["score"]}"
    puts "Datetime: #{res["data"]["datetime"]}"
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

    def get_responce(params)
      JSON.parse(RestClient.post(REQUEST_URL, params, :content_type => :json, :accept => :json))   
    end

    def missing_position
      return @missing_position unless @missing_position.nil? || @guesser.hit_a_char?

      #return all missing positions
      @missing_position = []
      offset = 0
      loop do 
        position = @guesser.current_word.index("*", offset)
        break if position.nil?
        @missing_position << position
        offset = position + 1
      end

      @missing_position
    end

    def reset_variable
      @filtered_words = nil
      @missing_position = []
      @guesser.clear_guessed_chars
    end

    def guess_most_frequent_vowel
      vowel_char_frequency = {} 
      ['E', 'A', 'O', 'I', 'U', 'Y'].each do |char|
        filtered_words.each do |word|
          if word.include?(char)
            vowel_char_frequency[char] = 0 if vowel_char_frequency[char].nil?
            vowel_char_frequency[char] += 1
          end
        end
      end

      vowel_sorted_frequency = vowel_char_frequency.sort_by{ |_k, v| -v }.to_h
      vowel_sorted_frequency.each do |k, _v|
        @guesser.guess(k)
        break if @guesser.hit_a_char?
      end
    end

    def guessing_most_frequent_letter?
      # calculate the frequency of letters in missing position
      char_frequency = {} 
      filtered_words.each do |word|
        missing_position.each do |position|
          char = word[position]
          char_frequency[char] = 0 if char_frequency[char].nil?
          char_frequency[char] += 1
        end
      end

      #remove the guessed letters
      char_frequency.delete_if{ |k, _v| @guesser.guessed_chars.include? k }

      #interrupt
      return false if char_frequency.empty?

      sorted_frequency = char_frequency.sort_by{ |_k, v| -v }.to_h

      #guess most frequent letter
      @guesser.guess(sorted_frequency.first[0])

      #remove the words containing the guessed letter if not hit a character
      @filtered_words.delete_if{ |word| word.include?(sorted_frequency.first[0]) } if !@guesser.hit_a_char?

      true
    end
end
