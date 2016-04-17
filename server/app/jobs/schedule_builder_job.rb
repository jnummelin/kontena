require 'celluloid'
require 'rufus-scheduler'
require_relative '../models/grid_service_schedule'
require_relative '../mutations/deploy'
require_relative '../mutations/start'

class ScheduleBuilderJob
  include Celluloid

  def initialize
    async.perform
    @scheduler = Rufus::Scheduler.new
  end

  def perform
    sleep 5 # just to keep things calm
    build_schedules

    @scheduler.join
  end


  def build_schedules
    GridSserviceSchedule.all.each do |schedule|
      mutation
      case schedule.command
        when 'deploy'
          @scheduler.send(schedule.type, schedule.schedule) do
            GridServices::Deploy.run(grid_service: schedule.grid_service)
          end
        when 'start'
          @scheduler.send(schedule.type, schedule.schedule) do
            GridServices::Start.run(grid_service: schedule.grid_service)
          end
      end  
    end
  end
end
