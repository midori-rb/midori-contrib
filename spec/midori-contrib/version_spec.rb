require './spec/spec_helper'
require 'midori-contrib'

RSpec.describe Midori::Contrib do
  describe 'version' do
    it 'should be readable' do
      expect(Midori::Contrib::VERSION).to be_a(String)
      # Backwards compatibility
      expect(MidoriContrib::VERSION).to be_a(String)
    end
  end
end
