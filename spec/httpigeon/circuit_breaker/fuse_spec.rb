require 'spec_helper'

describe HTTPigeon::CircuitBreaker::Fuse do
  let(:fuse_config) { HTTPigeon::CircuitBreaker::FuseConfig.new({ service_id: 'test.service' }) }
  let(:fuse) { described_class.new(fuse_config) }

  describe '.from_options' do
    it 'creates a new instance of Fuse' do
      instance = described_class.from_options({ service_id: 'test.service' })

      expect(instance).to be_a(described_class)
      expect(instance.service_id).to eq('test.service')
    end
  end

  describe '#execute' do
    before do
      allow(fuse.config.on_open_circuit).to receive(:call).and_return(nil)
    end

    context 'when the circuit is open' do
      before { allow(fuse).to receive(:open?).and_return(true) }

      it 'records the tripped event' do
        fuse.execute { 'response' }

        expect(fuse.tripped_count).to eq(1)
      end

      it 'calls on_open_circuit' do
        fuse.execute { 'response' }

        expect(fuse.config.on_open_circuit).to have_received(:call).with(
          instance_of(HTTPigeon::CircuitBreaker::NullResponse),
          instance_of(HTTPigeon::CircuitBreaker::CircuitOpenError)
        )
      end
    end

    context 'when the circuit is not open' do
      let(:response) { double('response', headers: {}) }

      before { allow(fuse).to receive(:open?).and_return(false) }

      context 'when the response has a maintenance mode header' do
        let(:response) { double('response', headers: { 'X-Maintenance-Mode-Timeout' => '30' }) }

        it 'opens the circuit and increments failure count' do
          fuse.execute { response }

          expect(fuse.storage.get('circuit:test.service:open')).to be true
          expect(fuse.failure_count).to eq(1)
          expect(fuse.config.on_open_circuit).to have_received(:call).with(
            response,
            instance_of(HTTPigeon::CircuitBreaker::CircuitOpenError)
          )
        end

        it 'uses the max expiration time if the server maintenance timeout is greater' do
          Timecop.freeze
          fuse.execute { double('response', headers: { 'X-Maintenance-Mode-Timeout' => '300' }) }

          expect(fuse.storage.get('circuit:test.service:open')).to be true
          expect(fuse.failure_count).to eq(1)

          Timecop.travel(181)

          expect(fuse.storage.get('circuit:test.service:open')).to be_nil
          expect(fuse.failure_count).to eq(0)
        end
      end

      context 'when the request is successful' do
        it 'records success and returns response' do
          return_value = nil

          expect { return_value = fuse.execute { response } }.not_to raise_error

          expect(fuse.success_count).to eq(1)
          expect(return_value).to eq(response)
        end
      end

      context 'when the request fails' do
        it 'raises an error and records failure when server error' do
          expect { fuse.execute { raise Faraday::ServerError.new({ status: 501 }) } }.to raise_error(Faraday::ServerError)
          expect(fuse.failure_count).to eq(1)
        end

        it 'raises an error and records failure when error code is in watchlist' do
          allow(fuse.config).to receive(:error_codes_watchlist).and_return([400])

          expect { fuse.execute { raise Faraday::Error.new({ status: 400 }) } }.to raise_error(Faraday::Error)
          expect(fuse.failure_count).to eq(1)
        end

        it 'raises an error and does not record failure when error code is not in watchlist' do
          expect { fuse.execute { raise Faraday::Error.new({ status: 400 }) } }.to raise_error(Faraday::Error)
          expect(fuse.failure_count).to eq(0)
        end

        context 'when failure rate is above threshold' do
          before do
            allow(fuse).to receive(:failure_rate).and_return(fuse.config.failure_rate_threshold + 0.1)
            allow(fuse).to receive(:failure_count).and_return(fuse.config.min_failures_count + 1)
          end

          it 'opens the circuit' do
            expect { fuse.execute { raise Faraday::ServerError.new({ status: 501 }) } }.to raise_error(Faraday::ServerError)
            expect(fuse.storage.get('circuit:test.service:open')).to be true
            expect(fuse.storage.get('circuit:test.service:half_open')).to be true
          end
        end

        context 'when failure count is above max failures count' do
          before { allow(fuse).to receive(:failure_count).and_return(fuse.config.max_failures_count + 1) }

          it 'opens the circuit' do
            expect { fuse.execute { raise Faraday::ServerError.new({ status: 501 }) } }.to raise_error(Faraday::ServerError)
            expect(fuse.storage.get('circuit:test.service:open')).to be true
            expect(fuse.storage.get('circuit:test.service:half_open')).to be true
          end
        end
      end
    end
  end

  describe '#open?' do
    it 'returns true when the circuit is open' do
      fuse.storage.set('circuit:test.service:open', true)

      expect(fuse.open?).to be true
    end

    it 'returns false when the circuit is not open' do
      expect(fuse.open?).to be false
    end
  end

  describe '#half_open?' do
    it 'returns true when the circuit is half open' do
      fuse.storage.set('circuit:test.service:half_open', true)

      expect(fuse.half_open?).to be true
    end

    it 'returns false when the circuit is not half open' do
      expect(fuse.half_open?).to be false
    end
  end

  describe '#failure_count' do
    it 'returns the failure count' do
      fuse.storage.set('run_stat:test.service:failure', 10)

      expect(fuse.failure_count).to eq(10)
    end
  end

  describe '#success_count' do
    it 'returns the success count' do
      fuse.storage.set('run_stat:test.service:success', 10)

      expect(fuse.success_count).to eq(10)
    end
  end

  describe '#tripped_count' do
    it 'returns the tripped count' do
      fuse.storage.set('run_stat:test.service:tripped', 10)

      expect(fuse.tripped_count).to eq(10)
    end
  end

  describe '#failure_rate' do
    it 'returns the failure rate' do
      fuse.storage.set('run_stat:test.service:failure', 10)
      fuse.storage.set('run_stat:test.service:success', 10)
      fuse.storage.set('run_stat:test.service:tripped', 10)

      expect(fuse.failure_rate.round(3)).to eq(0.667)
    end

    it 'returns 0 when there are no requests' do
      expect(fuse.failure_rate).to eq(0.0)
    end
  end
end
