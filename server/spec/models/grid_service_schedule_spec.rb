require_relative '../spec_helper'

describe GridServiceSchedule do
  it { should be_embedded_in(:grid_service) }
  it { should have_fields(:name, :type, :command, :schedule).of_type(String) }
end
