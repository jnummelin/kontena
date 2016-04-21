require_relative '../helpers/iface_helper'

module Kontena
  module Helpers
    module EtcdHelper
      
      include Kontena::Helpers::IfaceHelper
      
      @etcd = Etcd.client(host: '127.0.0.1', port: 2379)

      # @param [String] key
	  # @param [String, NilClass] value
	  def set(key, value)
	    if value.nil?
	      unset(key)
	    else
	      etcd.set(key, value: value)
	    end
	  end

	  # @param [String] key
	  def unset(key)
	    etcd.delete(key)
	    true
	  rescue
	    false
	  end

	  # @param [String] key
      def mkdir(key)
      	etcd.set(key, dir: true)
	  rescue Etcd::NotFile
	    false
	  end

	  # @param [String] key
      def rmdir(key)
      	etcd.delete(key, recursive: true)
	  end

	  # @param [String] key
	  # @return [Boolean]
	  def key_exists?(key)
	    etcd.get(key)
	    true
	  rescue
	    false
	  end

	  # @param [String] key
	  # @return [Array<String>]
	  def lsdir(key)
	    response = etcd.get(key)
	    response.children.map{|c| c.key}
	  rescue
	    []
	  end

    end
  end
end
