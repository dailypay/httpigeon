require 'spec_helper'

describe HTTPigeon::LogRedactor do
  describe '#redact' do
    before do
      allow(HTTPigeon).to receive(:redactor_string).and_return('<redacted>')
    end

    context 'when all filters are valid' do
      test_table = [
        {
          description: 'redacts all elements when data is an array',
          filters: %w[key_1::[FILTERED] key_2 /key_3=[0-9a-z]*/::key_3=<redacted> /(key_5=)(\d+)*/],
          data: [1, 'abc=123&key_3=supersecret007&xyz=789&key_5=000100100011', { key_1: 'duper-secret', key_4: 'public-knowledge' }],
          expected_result: [1, 'abc=123&key_3=<redacted>&xyz=789&key_5=000...<redacted>', { key_1: '[FILTERED]', key_4: 'public-knowledge' }]
        },
        {
          description: 'redacts all elements when data is a hash',
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
        {
          description: 'redacts payload when data is a string and a replacement is defined for an ungrouped filter',
          filters: %w[/key_3=[0-9a-z]*/::key_3=<redacted> /(key_4=)([0-9]+)*/],
          data: 'abc=123&key_3=supersecret007&xyz=789&key_4=0001',
          expected_result: 'abc=123&key_3=<redacted>&xyz=789&key_4=<redacted>'
        },
        {
          description: 'redacts payload when data is a string and a replacement is not defined for a grouped filter',
          filters: %w[/(key_3=)([0-9a-z]*)/ key_4],
          data: 'abc=123&key_3=supersecret007&xyz=789',
          expected_result: 'abc=123&key_3=sup...<redacted>&xyz=789'
        },
        {
          description: 'does not redact payload when data is a string and a replacement is not defined for an ungrouped filter',
          filters: %w[key_3=[0-9a-z]* key_4],
          data: 'abc=123&key_3=supersecret007&xyz=789',
          expected_result: 'abc=123&key_3=supersecret007&xyz=789'
        }
      ]

      test_table.each do |test_case|
        it test_case[:description].to_s do
          expect(described_class.new(log_filters: test_case[:filters]).redact(test_case[:data])).to eq(test_case[:expected_result])
        end
      end
    end

    context 'with default FilterPatterns' do
      describe 'PASSWORD' do
        subject(:redactor) { described_class.new(log_filters: [HTTPigeon::FilterPatterns::PASSWORD]) }

        it 'redacts password containing a dollar sign literal' do
          expect(redactor.redact('grant_type=client_credentials&password=$3cret!&scope=read')).to eq(
            'grant_type=client_credentials&password=$3c...<redacted>&scope=read'
          )
        end

        it 'redacts pass_word=value' do
          expect(redactor.redact('pass_word=s3cret!')).to eq('pass_word=s3c...<redacted>')
        end

        it 'redacts passWord=value' do
          expect(redactor.redact('passWord=s3cret!')).to eq('passWord=s3c...<redacted>')
        end

        it 'redacts password at end of string' do
          expect(redactor.redact('user=joe&password=supersecretpassword')).to eq(
            'user=joe&password=super...<redacted>'
          )
        end

        it 'redacts empty password value' do
          expect(redactor.redact('password=&next=login')).to eq('password=&next=login')
        end

        it 'does not match across newlines' do
          expect(redactor.redact("password=evil\nSECRET=leaked&next=1")).to eq(
            "password=<redacted>\nSECRET=leaked&next=1"
          )
        end
      end

      describe 'USERNAME' do
        subject(:redactor) { described_class.new(log_filters: [HTTPigeon::FilterPatterns::USERNAME]) }

        it 'redacts username=value' do
          expect(redactor.redact('username=johndoe&action=login')).to eq(
            'username=joh...<redacted>&action=login'
          )
        end

        it 'redacts user_name=value' do
          expect(redactor.redact('user_name=johndoe')).to eq('user_name=joh...<redacted>')
        end

        it 'redacts userName=value' do
          expect(redactor.redact('userName=johndoe')).to eq('userName=joh...<redacted>')
        end

        it 'redacts username at end of string' do
          expect(redactor.redact('token=abc&username=averylongusernamevalue')).to eq(
            'token=abc&username=averyl...<redacted>'
          )
        end
      end

      describe 'CLIENT_ID' do
        subject(:redactor) { described_class.new(log_filters: [HTTPigeon::FilterPatterns::CLIENT_ID]) }

        it 'redacts client_id=value' do
          expect(redactor.redact('client_id=abc123xyz&scope=read')).to eq(
            'client_id=abc...<redacted>&scope=read'
          )
        end

        it 'redacts clientId=value' do
          expect(redactor.redact('clientId=abc123xyz')).to eq('clientId=abc...<redacted>')
        end

        it 'redacts clientid=value' do
          expect(redactor.redact('clientid=abc123xyz')).to eq('clientid=abc...<redacted>')
        end
      end

      describe 'CLIENT_SECRET' do
        subject(:redactor) { described_class.new(log_filters: [HTTPigeon::FilterPatterns::CLIENT_SECRET]) }

        it 'redacts client_secret=value' do
          expect(redactor.redact('client_id=pub123&client_secret=topsecret123&grant_type=code')).to eq(
            'client_id=pub123&client_secret=top...<redacted>&grant_type=code'
          )
        end

        it 'redacts clientSecret=value' do
          expect(redactor.redact('clientSecret=topsecret123')).to eq('clientSecret=top...<redacted>')
        end

        it 'redacts clientsecret=value' do
          expect(redactor.redact('clientsecret=topsecret123')).to eq('clientsecret=top...<redacted>')
        end
      end

      describe 'EMAIL' do
        subject(:redactor) { described_class.new(log_filters: [HTTPigeon::FilterPatterns::EMAIL]) }

        it 'redacts email=value' do
          expect(redactor.redact('email=user@example.com&action=signup')).to eq(
            'email=use...<redacted>&action=signup'
          )
        end

        it 'redacts emailaddress=value' do
          expect(redactor.redact('emailaddress=user@example.com')).to eq(
            'emailaddress=use...<redacted>'
          )
        end

        it 'redacts email_address=value' do
          expect(redactor.redact('email_address=user@example.com')).to eq(
            'email_address=use...<redacted>'
          )
        end

        it 'redacts emailAddress=value' do
          expect(redactor.redact('emailAddress=user@example.com')).to eq(
            'emailAddress=use...<redacted>'
          )
        end
      end

      describe 'all patterns combined' do
        subject(:redactor) do
          described_class.new(log_filters: [
                                HTTPigeon::FilterPatterns::EMAIL,
                                HTTPigeon::FilterPatterns::PASSWORD,
                                HTTPigeon::FilterPatterns::USERNAME,
                                HTTPigeon::FilterPatterns::CLIENT_ID,
                                HTTPigeon::FilterPatterns::CLIENT_SECRET
                              ])
        end

        it 'redacts multiple sensitive params in one string' do
          data = 'username=johndoe&password=s3cure!&client_id=app123abc&client_secret=secretvalue1&email=test@mail.com'

          expect(redactor.redact(data)).to eq(
            'username=joh...<redacted>&password=s3c...<redacted>&client_id=app...<redacted>&client_secret=sec...<redacted>&email=tes...<redacted>'
          )
        end
      end
    end

    context 'when a filtered key holds a nested collection' do
      it 'fully redacts a nested hash instead of leaking fragments' do
        filters = %w[token]
        data = { token: { access: 'SUPER_SECRET_ACCESS_TOKEN_123456', refresh: 'REFRESH_SECRET_999' } }

        expect(described_class.new(log_filters: filters).redact(data)).to eq({ token: '<redacted>' })
      end

      it 'fully redacts a nested array instead of leaking fragments' do
        filters = %w[credentials]
        data = { credentials: %w[SUPER_SECRET_ONE SUPER_SECRET_TWO] }

        expect(described_class.new(log_filters: filters).redact(data)).to eq({ credentials: '<redacted>' })
      end
    end

    context 'when a content filter matches a string value inside a hash' do
      it 'redacts the secret regardless of the key name' do
        filters = [HTTPigeon::FilterPatterns::CLIENT_SECRET]
        data = { error_uri: 'https://idp/cb?client_id=abc&client_secret=REALSECRET' }

        expect(described_class.new(log_filters: filters).redact(data)).to eq(
          { error_uri: 'https://idp/cb?client_id=abc&client_secret=REA...<redacted>' }
        )
      end
    end

    context 'when a replacement contains a gsub backreference' do
      it 'treats the backreference literally instead of re-emitting the secret' do
        filters = ['/(password=)([^&]+)/::password=\2']
        data = 'https://api.example.com/auth?password=S3cr3tP@ssw0rd&grant_type=code'

        expect(described_class.new(log_filters: filters).redact(data)).to eq(
          'https://api.example.com/auth?password=\2&grant_type=code'
        )
      end
    end

    context 'when a grouped filter matches an empty capture' do
      it 'does not raise and leaves the empty value in place' do
        filters = %w[/(client_id=)([0-9a-z]+)*/]
        data = 'action=login&client_id=&next=home'

        expect { described_class.new(log_filters: filters).redact(data) }.not_to raise_error
        expect(described_class.new(log_filters: filters).redact(data)).to eq('action=login&client_id=&next=home')
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
