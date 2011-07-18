require 'spec_helper'
require 'mplayer/player'

class TestPlayer < MPlayer::Player
  attr_reader :log

  def initialize(*args)
    super
    @log = []
    on_event(:track_end) { |track|  @log << track }
  end
end

describe MPlayer::Player, em_synchrony: false  do
  around do |example|
    EM.synchrony do
      example.call
      EM.stop
    end
  end

  before do
    @track = MPlayer::Track.new File.join(RSpec.configuration.fixture_path, 'tiny.ogg'), 3.0
    @player = TestPlayer.new '-ao null'
  end
  after do
    @player.close
  end

  it "#play"  do
    @player.play( @track.path, muted: true ).should be_true

    @player.should_not be_stopped
    @player.should     be_loaded
    @player.should_not be_paused
    @player.track.path.should == @track.path
    @player.pos.should be_zero

    half_len = @track.length / 2.0
    EM::Synchrony.sleep half_len
    @player.pos.should be_within(0.15).of(half_len)

    @player.wait_for { !@player.loaded? }
    @player.log.map(&:path).should == [@track.path]
  end

  it "#play (paused)" do
    @player.play( @track.path, paused: true, muted: true ).should be_true

    @player.should_not be_stopped
    @player.should     be_loaded
    @player.should     be_paused
    @player.track.path.should == @track.path
    #@player.track.length.should == @track.length
    @player.pos.should be_zero

    @player.pos.should be_zero
    EM::Synchrony.sleep 0.25
    @player.pos.should be_zero

    @player.log.should be_empty
  end

#   def test_play_fail
#     assert_raise(RuntimeError) {  @player.play 'nonexistant-file'  }
#   end
# 
#   def test_playlist
#     @player.playlist = [@track.path, @track.path]
#     assert @player.play
# 
#     assert !@player.stopped?
#     assert  @player.loaded?
#     assert !@player.paused?
#     assert_equal @track, @player.track
# 
#     half_len = @track.length / 2.0
#     @player.process_for half_len
#     assert_in_delta half_len, @player.pos, 0.15, @player.pos
# 
#     @player.process_for half_len
#     assert_in_delta @track.length, @player.pos, 0.3, @player.pos
# 
#     @player.process_until { |p|  MplayerTest.play_log.any?  }
#     assert_equal [@track, 1.0], MplayerTest.play_log.shift
#     @player.process_until { |p|  p.loaded? }
# 
#     @player.process_for half_len
#     assert_in_delta half_len, @player.pos, 0.15, @player.pos
# 
#     @player.process_for half_len
#     assert_in_delta @track.length, @player.pos, 0.3, @player.pos
# 
#     @player.process_until { |p|  !p.loaded? }
#     assert_equal [@track, 1.0], MplayerTest.play_log.shift
#   end
end
