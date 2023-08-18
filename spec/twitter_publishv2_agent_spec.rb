require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TwitterPublishv2Agent do
  before(:each) do
    @valid_options = Agents::TwitterPublishv2Agent.new.default_options
    @checker = Agents::TwitterPublishv2Agent.new(:name => "TwitterPublishv2Agent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
