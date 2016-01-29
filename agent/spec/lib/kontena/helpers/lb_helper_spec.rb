require_relative '../../../spec_helper'
require_relative '../../../../lib/kontena/helpers/lb_helper'

describe Kontena::Helpers::LBHelper do

  let(:subject) { Class.new { include Kontena::Helpers::LBHelper }.new }

  describe '#parse_ports' do
    it "return parsed ports" do
      ports = subject.parse_ports("80:8080/http")
      expect(ports.size).to eq(1)
      expect(ports).to include({'mode' => 'http', 'internal' => '8080', 'external' => '80'})
    end

    it "return parsed ports with only internal port defined" do
      ports = subject.parse_ports("8080/http")
      expect(ports.size).to eq(1)
      expect(ports).to include({'mode' => 'http', 'internal' => '8080', 'external' => nil})
    end

    it "defaults to http protocol" do
      ports = subject.parse_ports("8080")
      expect(ports.size).to eq(1)
      expect(ports).to include({'mode' => 'http', 'internal' => '8080', 'external' => nil})
    end

    it "parses tcp ports" do
      ports = subject.parse_ports("2022:22/tcp")
      expect(ports.size).to eq(1)
      expect(ports).to include({'mode' => 'tcp', 'internal' => '22', 'external' => '2022'})
    end

    it "parses tcp and http ports" do
      ports = subject.parse_ports("2022:22/tcp,80:8080/http")
      expect(ports.size).to eq(2)
      expect(ports).to include({'mode' => 'tcp', 'internal' => '22', 'external' => '2022'}, {'mode' => 'http', 'internal' => '8080', 'external' => '80'})
    end
  end

end
