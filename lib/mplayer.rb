require 'pathname'
require 'thread'

class Mplayer

  Track = Struct.new :path, :length, :title

  @@MPlayerBin = ['/usr/bin/mplayer', '/usr/local/bin/mplayer']

  attr_accessor :playlist

  def paused?()  @loaded and @paused and not @stopped  end
  def loaded?()  @loaded   end
  def stopped?() @stopped  end
  def playing?() @loaded and not @paused and not @stopped  end
  def track()    @track    end
  def pos()      @pos      end

  def has_valid_mplayer_binary?
    @mplayer_bin = @@MPlayerBin.detect do |bin|
      FileTest.exists?(bin) && FileTest.executable?(bin)
    end
  end

  def initialize( opts = '' )
    raise "Can't run MPlayer binary (#{@@MPlayerBin})" unless has_valid_mplayer_binary?

    @stopped, @paused, @loaded = true, false, false
    @playlist = []
    @io = IO.popen "#{@mplayer_bin} -noconsolecontrols -idle -slave #{opts} 2>&1", 'r+'
    @io_queue = Queue.new
    @io_thread = Thread.new(self) { |p|  p.read_thread }
    @io_log = []
    ObjectSpace.define_finalizer self, Mplayer.create_finalizer(self)
    expect ['MPlayer', 'CPU:']
  end

  def on_track_end( track, pos )
debug "End (#{100 * pos / track.length}%): #{track.inspect}"
    play  unless stopped?
  end

  def close
    return  if @io.closed?
    stop
    quit!
    process
    @io.close
    @io_thread.join
  end

  def unmute()  mute(false)  end
  def mute( state = true )
    mute!( state ? 1 : 0 )
    expect "Mute: #{state ? 'enabled' : 'disabled'}"
  end

  def play( path = nil, opts = {} )
    path ||= @playlist.shift    unless path
    return false  unless path

    @loaded = false
    raise "File not found: #{path}"  unless FileTest.exists? path

    cmd = "loadfile #{path} 0"
debug "! #{cmd}"
    @io.puts cmd
    pause!  if opts[:paused] or opts[:muted]

    m = expect(%r[(Starting playback)|(Failed to open #{path}.*$)])
    raise m[0]  if m[2]

    if opts[:paused] or opts[:muted]
      process_until {  paused?  }
    else
      process_until {  loaded?  }
    end

    if opts[:muted]
      mute
      pause!  unless opts[:paused]
    end

    return true
  end

  def pause
    was_paused = paused?
    pause!
    process_until {  paused? != was_paused  }
  end

  def stop
    return  unless loaded?
    pause!  unless paused?
    @loaded, @stopped = false, true
    on_track_end track, pos
  end

  def method_missing( func, *args )
    super unless [?!, ??].include? func.to_s[-1]

    func = func.to_s
    op = func.slice!(-1)
debug "! #{func} #{args.join(' ')}"

    @io.puts "pausing_keep #{func} #{args.join(' ')}"
    if op == ??
      process_until {  not @io_log.empty?  }
      res = @io_log.pop
      return (m = res.match(%r{^ANS_([\w_]+)=('?)(.*)\2$})) ? m[3] : res
    end
  end

  def process( &blk )
    process_until do |p|
      blk.call(p)  if blk
      @io_queue.empty?
    end
  end

  def process_for( secs, &blk )
    end_time = Time.now + secs
    process_until do |p|
      (Time.now >= end_time) or (blk and blk.call(p))
    end
  end

  def process_until
    loop do
      if @io_queue.empty?
        break  if block_given? and yield(self)
        sleep 0.1
        next
      end

      str = @io_queue.pop

debug "< #{str}"  unless str[0] == ?A
      @paused = false
      case str
        when %r{^Playing (.*)\.$}
          @track = Track.new $1
          @stopped = false

        when %r{^A: \s*([\d]+\.[\d]+) .* of \s*([\d]+\.[\d]+) }
          pos, len = $1.to_f, $2.to_f

debug "< #{str}"  if track.length.nil? or pos != @pos
          @pos = pos
          unless track.length
            track.length = len
            @loaded = true
          end

        when %r{^Name: (.*)\s*$}        then  @track.title = $1
#        when %r{^Album: (.*)\s*$}       then  @track.album = $1
#        when %r{^Track: (.*)\s*$}       then  @track.num = $1.to_i

        when /=====  PAUSE  =====/
          @paused = true

        when ''
          next unless playing?
          @loaded = false
          track, pos, @track, @pos, @loaded = @track, @pos, nil, nil, false
          pos = track.length  unless paused?
          on_track_end track, pos

        else
          @io_log << str
      end

      break  if block_given? and yield(self)
    end
  end

protected

  def expect( str )
    case str
      when Array
        str.each { |s| return false unless expect(s) }
        return true

      when String
        line = nil
        process_until {  @io_log.any? and (line = @io_log.shift).include?(str)  }
        return line

      when Regexp
        m = nil
        process_until {  @io_log.any? and m = @io_log.shift.match(str)  }
        return m
    end
  end

  def read_thread
    buff = ''
    begin
      until @io.eof?
        buff += @io.read 1
        next unless (i = buff.index(/[\r\n]/))

        @io_queue.push buff.slice!(0, i+1).strip
      end

    rescue
      return
    end
  end

  def debug( str )
    unless ENV['DEBUG'].to_i.zero?
      $stdout.puts str
      $stdout.flush
    end
  end

  def Mplayer.create_finalizer( player )
    proc {  player.close  }
  end

end
