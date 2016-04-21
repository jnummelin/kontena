require_relative '../../../spec_helper'

describe Kontena::Workers::ServiceDiscoveryWorker do

  before(:each) do
    Celluloid.boot
    allow(subject.wrapped_object).to receive(:etcd).and_return(etcd)
    allow(Docker::Container).to receive(:get).and_return(container)
  end

  after(:each) { Celluloid.shutdown }

  let(:etcd) { spy(:etcd) }
  let(:start_event) { spy(:event, id: 'foobar', status: 'start') }
  let(:destroy_event) { spy(:event, id: 'foobar', status: 'destroy') }
  let(:container) {
    spy(:container, id: '12345',
      env_hash: {
        'FOO' => 'bar',
        'SOME_VAR' => 'some value'
      },
      labels: {
        'io.kontena.load_balancer.name' => 'lb',
        'io.kontena.service.name' => 'test-api',
        'io.kontena.container.name' => 'test-api-1',
        'io.kontena.service.instance_number' => '1',
        'io.kontena.container.overlay_cidr' => '1.2.3.4'
      }
    )
  }
  let(:etcd_prefix) { described_class::ETCD_PREFIX }

  describe '#initialize' do
    it 'starts to listen container events' do
      expect(subject.wrapped_object).to receive(:on_container_event).once.with('container:event', start_event)
      Celluloid::Notifications.publish('container:event', start_event)

      sleep 0.05
    end
  end


  describe '#on_container_event' do
    it 'adds new instance' do
        expect(subject.wrapped_object).to receive(:add_instance).once
        subject.on_container_event('container:event', start_event)
    end

    it 'removes instance' do
        expect(subject.wrapped_object).to receive(:delete_instance).once
        subject.on_container_event('container:event', destroy_event)
    end
  end

  describe '#add_instance' do
    it 'sets default values to etcd' do
      storage = {}
      allow(etcd).to receive(:set) do |key, value|
        storage[key] = value[:value]
      end

      subject.add_instance(container)
      expected_values = {
        "#{etcd_prefix}/test-api/1" => nil,
        "#{etcd_prefix}/test-api/1/ip" => '1.2.3.4',
        "#{etcd_prefix}/test-api/1/name" => 'test-api-1',
        "#{etcd_prefix}/test-api/1/env/FOO" => 'bar',
        "#{etcd_prefix}/test-api/1/env/SOME_VAR" => 'some value'
      }

      expected_values.each do |k, v|
        expect(storage[k]).to eq(v)
      end
    end
  end

  describe '#delete_instance' do
    it 'deletes instance' do
      allow(etcd).to receive(:lsdir).and_return(["foo"])
      expect(etcd).to receive(:delete).once.with("#{etcd_prefix}/test-api/1", {recursive: true})

      subject.delete_instance(container)
    end

    it 'deletes service dir after all instances removed' do
      allow(subject.wrapped_object).to receive(:lsdir).and_return([])
      expect(etcd).to receive(:delete).once.with("#{etcd_prefix}/test-api/1", {recursive: true})
      expect(etcd).to receive(:delete).once.with("#{etcd_prefix}/test-api", {recursive: true})
      subject.delete_instance(container)
    end
  end
end
