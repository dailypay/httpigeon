require 'spec_helper'

describe HTTPigeon::CircuitBreaker::MemoryStore do
  let(:storage) { described_class.new(described_class::MAX_SAMPLE_WINDOW) }

  describe 'MAX_SAMPLE_WINDOW' do
    it 'is set to 180' do
      expect(described_class::MAX_SAMPLE_WINDOW).to eq(180)
    end
  end

  describe '#new' do
    it 'sets the sample window to the given value if less than max' do
      storage = described_class.new(10)

      expect(storage.sample_window).to eq(10)
    end

    it 'sets the sample window to MAX_SAMPLE_WINDOW if the given value is greater' do
      storage = described_class.new(described_class::MAX_SAMPLE_WINDOW + 1)

      expect(storage.sample_window).to eq(described_class::MAX_SAMPLE_WINDOW)
    end
  end

  describe '#get' do
    it 'returns the value for the given key' do
      storage.set('key', 'value')

      expect(storage.get('key')).to eq('value')
    end

    it 'returns nil if the key does not exist' do
      expect(storage.get('key')).to be_nil
    end
  end

  describe '#set' do
    it 'stores the value for the given key' do
      storage.set('key', 'value')

      expect(storage.get('key')).to eq('value')
    end

    it 'overwrites the value for the given key' do
      storage.set('key', 'value')
      storage.set('key', 'new_value')

      expect(storage.get('key')).to eq('new_value')
    end

    it 'returns the value' do
      expect(storage.set('key', 'value')).to eq('value')
    end

    it 'expires the key after the given time' do
      Timecop.freeze

      storage.set('key', 'value', expires_in: 2)

      Timecop.travel(3)

      expect(storage['key']).to be_nil
    end

    it 'does not set expiration beyond max sample window limit' do
      Timecop.freeze

      storage.set('max-exp-key', 'value', expires_in: described_class::MAX_SAMPLE_WINDOW + 5)

      Timecop.travel(described_class::MAX_SAMPLE_WINDOW + 1)

      expect(storage['max-exp-key']).to be_nil
    end
  end

  describe '#increment' do
    it 'increments the value for the given key' do
      storage.increment('key')

      expect(storage['key']).to eq(1)
    end

    it 'increments the value by the given amount' do
      storage.increment('key')
      storage.increment('key', 5)

      expect(storage['key']).to eq(6)
    end

    it 'resets the count if the current has expired' do
      Timecop.freeze
      storage.increment('key', 3, expires_in: 2)

      Timecop.travel(3)

      storage.increment('key')

      expect(storage['key']).to eq(1)
    end
  end

  describe '#key?' do
    it 'returns true if the key exists' do
      storage.set('key', 'value')

      expect(storage.key?('key')).to be true
    end

    it 'returns false if the key does not exist' do
      expect(storage.key?('key')).to be false
    end
  end

  describe '#delete' do
    it 'deletes the key' do
      storage.set('del-key', 'value')
      storage.delete('del-key')

      expect(storage['del-key']).to be_nil
    end
  end
end
