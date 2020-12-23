require './spec/spec_helper'
require 'midori-contrib/redic'
require 'ohm'

RSpec.describe Ohm do
  describe 'driver' do
    it 'should set a value and read it' do
      answer = []
      Thread.new do
        Fiber.set_scheduler Evt::Scheduler.new
        Fiber.schedule do
          Ohm.redis = Redic.new
          Ohm.redis.call 'SET', 'foo', 'bar'
          answer << Ohm.redis.call('GET', 'foo')
        end
        answer << 0
      end.join

      expect(answer).to eq([0, 'bar'])
    end
  end
end
