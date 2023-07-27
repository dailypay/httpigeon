require_relative "../test_helper"

class HTTPigeon::LogRedactorTest < HTTPigeon::TestCase
  describe '#redact' do
    let(:string_filters) { [HTTPigeon::Filter.new(:string, /key_3=[0-9a-z]*/i, 'key_3=')] }
    let(:data) { nil }

    let(:redactor) do
      HTTPigeon::LogRedactor.new(hash_filter_keys: [:key_1, :key_2], string_filters: string_filters)
    end

    context 'when data is an array' do
      let(:data) { [1, 'abc-123&key_3=supersecret007&xyz-789', { key_1: 'duper-secret', key_4: 'public-knowledge' }] }

      it 'filters all elements' do
        HTTPigeon.stub(:redactor_string, '<redacted>') do
          assert_equal [1, 'abc-123&key_3=<redacted>&xyz-789', { key_1: '<redacted>', key_4: 'public-knowledge' }], redactor.redact(data)
        end
      end
    end

    context 'when data is a string' do
      let(:data) { 'abc-123&key_3=supersecret007&xyz-789' }

      context 'when a :sub_prefix is defined' do
        it 'filters the string' do
          HTTPigeon.stub(:redactor_string, '<redacted>') do
            assert_equal 'abc-123&key_3=<redacted>&xyz-789', redactor.redact(data)
          end
        end
      end

      context 'when a :sub_prefix is not defined' do
        let(:string_filters) { [HTTPigeon::Filter.new(:string, /key_3=[0-9a-z]*/i, nil, 'key_3=***')] }

        it 'filters the string' do
          HTTPigeon.stub(:redactor_string, '<redacted>') do
            assert_equal 'abc-123&key_3=***&xyz-789', redactor.redact(data)
          end
        end
      end
    end

    context 'when data is a hash' do
      let(:data) { { key_1: 'duper-secret', key_4: 'public-knowledge', key_5: [{ key_2: 'duper-duper-secret' }, { key_3: 'also-public-knowledge' }] } }

      it 'filters all elements' do
        HTTPigeon.stub(:redactor_string, '<redacted>') do
          expected = { key_1: '<redacted>', key_4: 'public-knowledge', key_5: [{ key_2: '<redacted>' }, { key_3: 'also-public-knowledge' }] }

          assert_equal expected, redactor.redact(data)
        end
      end
    end
  end
end
