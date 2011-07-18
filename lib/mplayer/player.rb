require 'mplayer/io'

class MPlayer::Player
  attr_accessor :playlist

  def initialize( mplayer_opts = '' )
    @playlist = []

    raise "Can't find MPlayer binary: #{BinPaths.join(', ')}"  unless mplayer_bin
    cmd = "#{@mplayer_bin} -noconsolecontrols -nolirc -idle -slave #{mplayer_opts}"
    @io = EM.popen(cmd, MPlayer::IO)

    ObjectSpace.define_finalizer self, MPlayer::Player.create_finalizer(self)
    @io.expect 'MPlayer'
  end

  def as_json
    @io.as_json.update( playlist: playlist.map(&:as_json) )
  end

  def close
    return  if @io.closed?
    stop
    quit!
    @io.close_connection_after_writing
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

    send_data "loadfile \"#{path}\" 0\n"
    pause!  if opts[:paused] or opts[:muted]

    m = expect(%r{(starting playback)|(failed to open)}i)
    raise m[0]  if m[2]

    if opts[:paused] or opts[:muted]
      wait_for { paused? }
    else
      wait_for { loaded? }
    end

    if opts[:muted]
      mute
      pause!  unless opts[:paused]
    end

    true
  end

  def pause
    was_paused = paused?
    pause!
    wait_for { paused? != was_paused }
  end

  def stop
    return  unless loaded?
    pause!  unless paused?
    track, @track = @track, nil
    @io.send(:trigger_event, :track_end, track)
  end

  def method_missing(method, *args, &blk)
    return @io.send(method, *args, &blk)  if @io.respond_to?(method)
    method = method.to_s
    super unless [?!, ??].include? method[-1]

    op = method.slice!(-1)
debug "! #{method} #{args.join(' ')}"

    @io.send_data "pausing_keep #{method} #{args.join(' ')}\n"
    if op == ??
      res = wait_for {  |l|  l  }
      return (m = res.match(%r{^ANS_([\w_]+)=('?)(.*)\2$})) ? m[3] : res
    end
  end

protected
  BinPaths = %w(/usr/bin/mplayer /usr/local/bin/mplayer)

  def mplayer_bin
    @mplayer_bin ||= BinPaths.find do |bin|
      FileTest.exists?(bin) && FileTest.executable?(bin)
    end
  end

  def when_track_ends( track )
debug "end #{track.inspect}"
    play  unless stopped?
  end

  def self.create_finalizer(player)
    proc {  player.close  }
  end
end
