require 'docker'
require_relative '../logging'
require_relative '../helpers/etcd_helper'

module Kontena::Workers
  class ServiceDiscoveryWorker
    include Celluloid
    include Celluloid::Notifications
    include Kontena::Logging
    include Kontena::Helpers::EtcdHelper

    ETCD_PREFIX = '/kontena/services'

    def initialize
      info 'ServiceDiscoveryWorker initialized'
      subscribe('container:event', :on_container_event)
    end

    def start
      sleep 1 until weave_running?
      info 'attaching network to existing containers'
      Docker::Container.all(all: false).each do |container|
        self.add_instance(container)
      end
    end

    # @param [String] topic
    # @param [Docker::Event] event
    def on_container_event(topic, event)
      if event.status == 'start'
        container = Docker::Container.get(event.id) rescue nil
        if container
          self.add_instance(container)
        end
      elsif event.status == 'destroy'
        self.delete_instance(event)
      end
    end

    # @param [Docker::Container] container
    def add_instance(container)
      deploy_rev = container.labels['io.kontena.container.deploy_rev']
      instance_number = container.labels['io.kontena.service.instance_number']
      overlay_cidr = container.labels['io.kontena.container.overlay_cidr']
      container_name = container.labels['io.kontena.container.name']
      service_name = container.labels['io.kontena.service.name']
      grid_name = container.labels['io.kontena.grid.name']

      etcd_path = "#{ETCD_PREFIX}/#{service_name}"
      mkdir("#{etcd_path}/#{instance_number}")

      set("#{etcd_path}/#{instance_number}/ip", overlay_cidr)
      set("#{etcd_path}/#{instance_number}/name", container_name)

      container.env_hash.each do  |key, value|
        set("#{etcd_path}/#{instance_number}/env/#{key}", value)        
      end

    
    rescue Docker::Error::NotFoundError

    rescue => exc
      error "#{exc.class.name}: #{exc.message}"
      error exc.backtrace.join("\n")
    end

    def delete_instance(container)
      service_name = container.labels['io.kontena.service.name']
      instance_number = container.labels['io.kontena.service.instance_number']

      etcd_path = "#{ETCD_PREFIX}/#{service_name}"
      rmdir("#{etcd_path}/#{instance_number}")
      if lsdir("#{etcd_path}").size == 0
        # If last instance removed, remove the whole dir of the service
        rmdir("#{etcd_path}")
      end
    end
  end
end
