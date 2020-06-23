require 'spec_helper'

describe service('ecs-agent') do
  it { should be_enabled }
end
