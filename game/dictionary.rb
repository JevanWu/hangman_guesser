class Dictionary

  def self.init
    @dictionary = []
    File.open('lib/dictionary.txt', 'r') do |f|
      f.each_line do |line|
        @dictionary << line.strip
      end
    end
  end

  def self.all_words
    @dictionary
  end
end
