require 'spec_helper'

describe HTTPigeon::LogRedactor do
  describe '#redact' do
    before do
      allow(HTTPigeon).to receive(:redactor_string).and_return('<redacted>')
    end

    context 'when all filters are valid' do
      let(:test_table) do
        [
          { # it redacts all elements when data is an array
            filters: %w[key_1::[FILTERED] key_2 /key_3=[0-9a-z]*/::key_3=<redacted> /(key_5=)(\d+)*/],
            data: [1, 'abc=123&key_3=supersecret007&xyz=789&key_5=000100100011', { key_1: 'duper-secret', key_4: 'public-knowledge' }],
            expected_result: [1, 'abc=123&key_3=<redacted>&xyz=789&key_5=000...<redacted>', { key_1: '[FILTERED]', key_4: 'public-knowledge' }]
          },
          { # it redacts all elements when data is a hash
            filters: %w[key_1::[FILTERED] key_7 key_8::[FILTERED] key_2 /key_3=[0-9a-z]*/::key_3=<redacted> /(key_5=)(\d+)*/],
            data: {
              key_1: 'duper-secret',
              key_4: 'public-knowledge',
              key_5: [{ key_2: 'duper-duper-secret' * 2 }, { key_3: 'also-public-knowledge' }],
              key_6: { key_7: '', key_8: 'noby-can-ever-know' }
            },
            expected_result: {
              key_1: '[FILTERED]',
              key_4: 'public-knowledge',
              key_5: [{ key_2: 'duper-...<redacted>...secret' }, { key_3: 'also-public-knowledge' }],
              key_6: { key_7: '', key_8: '[FILTERED]' }
            }
          },
          { # it redacts payload when data is a string and a replacement is defined for an ungrouped filter
            filters: %w[/key_3=[0-9a-z]*/::key_3=<redacted> /(key_4=)([0-9]+)*/],
            data: 'abc=123&key_3=supersecret007&xyz=789&key_4=0001',
            expected_result: 'abc=123&key_3=<redacted>&xyz=789&key_4=<redacted>'
          },
          { # it redacts payload when data is a string and a replacement is not defined for a grouped filter
            filters: %w[/(key_3=)([0-9a-z]*)/ key_4],
            data: 'abc=123&key_3=supersecret007&xyz=789',
            expected_result: 'abc=123&key_3=sup...<redacted>&xyz=789'
          },
          { # it does not redact payload when data is a string and a replacement is not defined for an ungrouped filter
            filters: %w[key_3=[0-9a-z]* key_4],
            data: 'abc=123&key_3=supersecret007&xyz=789',
            expected_result: 'abc=123&key_3=supersecret007&xyz=789'
          }
        ]
      end

      it 'redacts payloads as expected' do
        test_table.each do |test_case|
          expect(described_class.new(log_filters: test_case[:filters]).redact(test_case[:data])).to eq(test_case[:expected_result])
        end
      end
    end

    context 'when filters include an invalid regex' do
      it 'raises an error' do
        filters = %w[/key_3=[0-9a-z]*/im::key_3=<redacted> key_4]
        data = 'abc=123&key_3=supersecret007&xyz=789'

        expect { described_class.new(log_filters: filters).redact(data) }.to raise_error do |error|
          expect(error).to be_a(HTTPigeon::LogRedactor::UnsupportedRegexpError)
          expect(error.message).to eq('The specified regexp is invalid: /key_3=[0-9a-z]*/im. NOTE: Only ignore case (/i) is currently supported.')
        end
      end
    end
  end
end
