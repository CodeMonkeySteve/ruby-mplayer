module MPlayer

class Track
  attr_accessor :path, :length, :title
  attr_accessor :artist, :album, :num, :year

  def initialize(path, length = nil, title = nil)
    @path, @length, @title = path, length, title
  end
end

end
