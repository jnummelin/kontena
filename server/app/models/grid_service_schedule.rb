class GridServiceSchedule
  include Mongoid::Document

  field :name, type: String
  field :type, type: String # every / cron
  field :command, type: String # deploy / start
  field :schedule, type: String
  
  embedded_in :grid_service


end
