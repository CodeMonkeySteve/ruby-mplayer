require 'spec_helper'
require 'mplayer/io'

describe MPlayer::IO, em_synchrony: true  do
  before do
    @io = Class.new { include  MPlayer::IO }.new
    @io.should     be_stopped
    @io.should_not be_paused
    @io.should_not be_loaded
  end

  it "#wait_for" do
    EM.next_tick { @io.receive_line 'foo' }
    @io.wait_for { 123 }.should == 123
  end

  it "#wait_for (line)" do
    EM.next_tick { @io.receive_line 'foo' }
    @io.wait_for { |line|  line }.should == 'foo'
  end

  it "#expect (substring)" do
    EM.next_tick { @io.receive_line 'foo' }
    @io.expect('fo').should == 'foo'
  end
end
