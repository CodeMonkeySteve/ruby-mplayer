require 'em/protocols/linetext2'
require 'em-synchrony'
require 'mplayer/track'

module MPlayer::IO
  include EventMachine::Protocols::LineText2

  Events = [:track_start, :pos_change, :paused, :track_end].freeze

  attr_reader :track, :pos

  def loaded?()   @loaded                           end
  def stopped?()  @stopped                          end
  def paused?()   @paused && @loaded && !@stopped   end
  def playing?() !@paused && @loaded && !@stopped   end
  def closed?()   @closed  end
  def status()    %w(playing paused stopped loaded).find { |s|  send("#{s}?".to_sym) }.to_sym  end

  def initialize
    @stopped, @paused, @loaded = true, false, false
    @event_callbacks = {}
    @lt2_delimiter = %r{[\r\n]}
    @lt2_delimiter.define_singleton_method(:length) { 1 }
    Events.each { |ev|  @event_callbacks[ev] = [] }
  end

  def on_event(event, &blk)
    ev = @event_callbacks[event]
    ev << blk  if blk
    ev
  end

  def as_json
    {
      status: status,
      pos: pos,
      track: track && track.as_json,
    }
  end

  def expect( str )
    res = nil
    case str
      when Array  then  wait_for { |l| l.include?(str[0]) && (res = str.shift) && str.empty? }
      when String then  wait_for { |l| l.include?(str) && (res = l)  }
      when Regexp then  wait_for { |l| res = l.match(str)  }
    end
    res
  end

  def wait_for(&blk)
    if blk.arity.zero?
      res = blk.call
      return res  if res
    end

    @wait_for = blk
    EM::Synchrony.sync(@callback = EM::DefaultDeferrable.new)
  end

  def receive_line(line)
    line.chomp!
    ln = line.gsub %r{\e\[\S}, ''  # strip ANSI sequences
    ln.strip!

debug "< #{ln.inspect}"  unless ln.start_with?('A:')
    @paused = false
    case ln
      when %r{^Playing (.*)\.$}
        @track = MPlayer::Track.new $1
        @stopped = false

      when %r{^A: \s*([\d]+\.[\d]+) .* of \s*([\d]+\.[\d]+) }
        pos, len = $1.to_f, $2.to_f

#debug "< #{ln}"  if (@track && !@track.length) || (pos != @pos)
        if @track && !@track.length
          @track.length = len
          @loaded = true
        end
        @track.length = pos  if pos > @track.length
        if @pos != pos
          @pos = pos
          trigger_event :pos_change, @pos
        end

      when %r{(Title|Name): (.*)\s*$}   then  @track.title = $2
      when %r{Artist: (.*)\s*$}         then  @track.artist = $1
      when %r{Album: (.*)\s*$}          then  @track.album = $1
      when %r{Track: (.*)\s*$}          then  @track.num = $1.to_i
      when %r{Year: (.*)\s*$}
        @track.year = $1.to_i
        trigger_event :track_start, @track

      when /=====  PAUSE  =====/
        @paused = true
        trigger_event :paused

      when ''
        return unless line.empty? && playing?
        @loaded, @stopped  = false, true
        track, @track = @track, nil
        pos, @pos = @pos, nil
        pos = track.length  unless paused?
        trigger_event :track_end, track

      else
        if @wait_for && (@wait_for.arity == 1) && (res = @wait_for.call(ln))
          @wait_for = nil
          callback, @callback = @callback, nil
          callback.set_deferred_status( :succeeded, res )
        end
    end

    if @wait_for && (@wait_for.arity == 0) && (res = @wait_for.call)
      @wait_for = nil
      callback, @callback = @callback, nil
      callback.set_deferred_status( :succeeded, res )
    end
  end

  def send_data(data)
    debug "! #{data}"
    super
  end

  def unbind
    super
    @closed = true
  end

protected
  def trigger_event(event, *args)
    event = event.to_sym
    raise "Unknown event: #{event}"  unless @event_callbacks.include?(event)
debug "event: #{event}(#{args.map(&:inspect).join(', ')})"  if event != :pos_change
    @event_callbacks[event].each { |ev|  ev.call(*args) }
  end

  def debug( str )
    unless ENV['DEBUG'].to_i.zero?
      $stdout.puts str
      $stdout.flush
    end
  end
end
