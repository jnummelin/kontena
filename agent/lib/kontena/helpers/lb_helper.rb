module Kontena
  module Helpers
    module LBHelper

      ##
      #
      # @return Hash
      def parse_ports(input)
        ports = []
        input.split(',').each { |port|
          port_mapping, mode = port.split('/')
          mode = 'http' if mode.nil?
          external, internal = port_mapping.split(':')
          if internal.nil?
            internal = external
            external = nil
          end
          ports << {
            'mode' => mode,
            'internal' => internal,
            'external' => external
          }
        }

        ports
      end

    end
  end
end
