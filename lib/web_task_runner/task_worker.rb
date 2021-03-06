require 'sinatra'
require 'sidekiq'
require 'sidekiq-status'

require_relative '../web_task_runner.rb'

class WebTaskRunner < Sinatra::Application
  class TaskWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    attr_accessor :params

    def perform(params = nil)
      return if WebTaskRunner.current_state == 'idle'

      self.params = HashWithIndifferentAccess[params]

      exec

      puts "Job ##{job_number} done."
      WebTaskRunner.job_ended
    end

    def job_number
      job_number = 0
      klass = self.class
      WebTaskRunner.jobs.each_with_index do |job, i|
        if job == klass
          job_number = i + 1
          break
        end
      end
      job_number
    end

    def exec
      puts <<-EOF
        Define the work in #{self.class}#exec!
      EOF
    end
  end

  class HashWithIndifferentAccess < Hash
    alias_method :regular_reader, :[] unless method_defined?(:regular_reader)

    def [](k)
      k = k.to_s unless k.is_a?(String)
      regular_reader(k)
    end
  end
end
