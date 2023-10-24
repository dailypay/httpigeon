require 'spec_helper'

describe HTTPigeon::Configuration do
  describe '#new' do
    it 'sets the expected defaults' do
      config = described_class.new

      expect(config.default_event_type).to eq('http.outbound')
      expect(config.default_filter_keys).to be_empty
      expect(config.redactor_string).to eq('[FILTERED]')
      expect(config.log_redactor).to be_nil
      expect(config.event_logger).to be_nil
      expect(config.auto_generate_request_id).to be true
      expect(config.notify_all_exceptions).to be false
      expect(config.exception_notifier).to be_nil
    end
  end
end
