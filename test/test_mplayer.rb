require 'test/unit'
require 'mplayer'

FixturePath = File.join File.dirname(__FILE__), 'fixtures/'

class MplayerTest < Test::Unit::TestCase

  def MplayerTest.play_log()  @@play_log end

  def setup
    @@play_log = []
    @track = Mplayer::Track.new File.join(FixturePath, 'tiny.ogg'), 3.0

    @player = Mplayer.new '-ao null'
    assert !@player.loaded?

    def @player.on_track_end( track, pos )
      MplayerTest.play_log << [track, pos / track.length]
      super
    end
  end

  def teardown
    @player.close
  end

  def test_create_destroy
  end

  def test_play
    assert @player.play(@track[:path])

    assert !@player.stopped?
    assert  @player.loaded?
    assert !@player.paused?
    assert_equal @track, @player.track

    half_len = @track[:length] / 2.0
    @player.process_for half_len
    assert_in_delta half_len, @player.pos, 0.15, @player.pos

    @player.process_until { |p|  not p.loaded? }
   assert_equal [[@track, 1.0]], MplayerTest.play_log
  end

  def test_play_paused
    assert @player.play( @track[:path], :paused => true )

    assert !@player.stopped?
    assert  @player.loaded?
    assert  @player.paused?
    assert_equal @track[:path], @player.track[:path]
    assert_equal @track[:length], @player.track[:length]

    assert_equal 0.0, @player.pos
    @player.process_for 0.25
    assert_equal 0.0, @player.pos

    assert MplayerTest.play_log.empty?
  end

  def test_play_fail
    assert_raise(RuntimeError) {  @player.play 'nonexistant-file'  }
  end

  def test_playlist
    @player.playlist = [@track.path, @track.path]
    assert @player.play

    assert !@player.stopped?
    assert  @player.loaded?
    assert !@player.paused?
    assert_equal @track, @player.track

    half_len = @track.length / 2.0
    @player.process_for half_len
    assert_in_delta half_len, @player.pos, 0.15, @player.pos

    @player.process_for half_len
    assert_in_delta @track.length, @player.pos, 0.3, @player.pos

    @player.process_until { |p|  MplayerTest.play_log.any?  }
    assert_equal [@track, 1.0], MplayerTest.play_log.shift
    @player.process_until { |p|  p.loaded? }

    @player.process_for half_len
    assert_in_delta half_len, @player.pos, 0.15, @player.pos

    @player.process_for half_len
    assert_in_delta @track.length, @player.pos, 0.3, @player.pos

    @player.process_until { |p|  !p.loaded? }
    assert_equal [@track, 1.0], MplayerTest.play_log.shift
  end

end