require_relative "../test_helper"

class HTTPigeon::LogRedactorTest < HTTPigeon::TestCase
  describe '#redact' do
    let(:data) { nil }
    let(:log_filters) { %w[key_1::[FILTERED] key_2 /key_3=[0-9a-z]*/::key_3=<redacted> /(key_5=)(\d+)*/] }

    let(:redactor) do
      HTTPigeon::LogRedactor.new(log_filters: log_filters)
    end

    context 'when data is an array' do
      let(:data) { [1, 'abc=123&key_3=supersecret007&xyz=789&key_5=000100100011', { key_1: 'duper-secret', key_4: 'public-knowledge' }] }

      it 'redacts all elements' do
        HTTPigeon.stub(:redactor_string, '<redacted>') do
          assert_equal [1, 'abc=123&key_3=<redacted>&xyz=789&key_5=000...<redacted>', { key_1: '[FILTERED]', key_4: 'public-knowledge' }], redactor.redact(data)
        end
      end
    end

    context 'when data is a string' do
      let(:log_filters) { %w[/key_3=[0-9a-z]*/::key_3=<redacted> key_4] }
      let(:data) { 'abc=123&key_3=supersecret007&xyz=789' }

      context 'when a replacement is defined' do
        it 'redacts the string' do
          HTTPigeon.stub(:redactor_string, '<redacted>') do
            assert_equal 'abc=123&key_3=<redacted>&xyz=789', redactor.redact(data)
          end
        end
      end

      context 'when a replacement is not defined' do
        context 'and the pattern is not grouped' do
          let(:log_filters) { %w[key_3=[0-9a-z]* key_4] }

          it 'does not redact the string' do
            HTTPigeon.stub(:redactor_string, '<redacted>') do
              assert_equal data, redactor.redact(data)
            end
          end
        end

        context 'and the pattern is grouped' do
          let(:log_filters) { %w[/(key_3=)([0-9a-z]*)/ key_4] }

          it 'does redacts the string' do
            HTTPigeon.stub(:redactor_string, '<redacted>') do
              assert_equal 'abc=123&key_3=sup...<redacted>&xyz=789', redactor.redact(data)
            end
          end
        end
      end
    end

    context 'when data is a hash' do
      let(:data) { { key_1: 'duper-secret', key_4: 'public-knowledge', key_5: [{ key_2: 'duper-duper-secret' }, { key_3: 'also-public-knowledge' }] } }

      it 'redacts all elements' do
        HTTPigeon.stub(:redactor_string, '<redacted>') do
          expected = { key_1: '[FILTERED]', key_4: 'public-knowledge', key_5: [{ key_2: 'duper...<redacted>' }, { key_3: 'also-public-knowledge' }] }

          assert_equal expected, redactor.redact(data)
        end
      end
    end

    context 'when a regex is invalid' do
      let(:log_filters) { %w[/key_3=[0-9a-z]*/im::key_3=<redacted> key_4] }
      let(:data) { 'abc=123&key_3=supersecret007&xyz=789' }

      it 'raises an error' do
        error = assert_raises(HTTPigeon::LogRedactor::UnsupportedRegexpError) { redactor.redact(data) }

        assert_equal 'The specified regexp is invalid: /key_3=[0-9a-z]*/im. NOTE: Only ignore case (/i) is currently supported.', error.message
      end
    end
  end
end
