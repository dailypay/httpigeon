require 'spec_helper'

describe HTTPigeon::Request do
  describe '.get' do
    it 'makes request with expected arguments' do
      request_double = instance_double(described_class, run: { hello: 'hi' }, response: 'faraday-response')
      endpoint = 'https://dummyjson.com/users/search'
      query = { q: 'John' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_return(request_double)

      response = described_class.get(endpoint, query, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ hello: 'hi' })
      expect(response.raw_response).to eq('faraday-response')
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
      expect(request_double).to have_received(:run).with(method: :get, path: '', payload: query)
    end
  end

  describe '.post' do
    it 'makes request with expected arguments' do
      request_double = instance_double(described_class, run: { hello: 'hi' }, response: 'faraday-response')
      endpoint = 'https://dummyjson.com/users/add'
      payload = { firstName: 'John', lastName: 'Doe' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_return(request_double)

      response = described_class.post(endpoint, payload, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ hello: 'hi' })
      expect(response.raw_response).to eq('faraday-response')
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
      expect(request_double).to have_received(:run).with(method: :post, path: '', payload: payload)
    end
  end

  describe '#new' do
    let(:custom_logger_klass) { double('some-custom-logger-klass') }

    before do
      logger_instance = double('instance-of-custom-logger')

      allow(logger_instance).to receive(:is_a?).with(HTTPigeon::Logger).and_return(true)
      allow(custom_logger_klass).to receive(:new).and_return(logger_instance)
    end

    context 'when a block is given' do
      it 'sets the expected default headers' do
        allow(SecureRandom).to receive(:uuid).and_return('secure-random-uuid')

        test_table = [
          { # when auto generate request id is turned off
            auto_generate_request_id: false,
            request_headers: { 'Foo' => 'barzz' },
            included_headers: { 'Accept' => 'application/json', 'Foo' => 'barzz' }
          },
          { # when auto generate request id is turned on
            auto_generate_request_id: true,
            request_headers: { 'Foo' => 'barzz' },
            included_headers: { 'Accept' => 'application/json', 'X-Request-Id' => 'secure-random-uuid', 'Foo' => 'barzz' }
          }
        ]

        test_table.each do |test_case|
          allow(HTTPigeon).to receive(:auto_generate_request_id).and_return(test_case[:auto_generate_request_id])

          request = described_class.new(base_url: 'https://www.example.com', headers: test_case[:request_headers]) do |conn|
            conn.request :json
            conn.response :json
          end

          expect(request.connection.headers.slice(*%w[Accept X-Request-Id Foo])).to eq(test_case[:included_headers])
        end
      end

      it 'sets the request options if provided' do
        request = described_class.new(base_url: 'https://www.example.com', options: { timeout: 10 }) do |conn|
          conn.request :json
          conn.response :json
        end

        expect(request.connection.options.timeout).to eq(10)
      end

      it 'does not use the default logger if a custom logger is not provided' do
        allow(HTTPigeon::Logger).to receive(:new)

        described_class.new(base_url: 'https://www.example.com') do |conn|
          conn.request :json
          conn.response :json
        end

        expect(HTTPigeon::Logger).not_to have_received(:new)
      end

      it 'sets the custom :httpigeon_logger if provided and is a type of httpigeon logger' do
        allow(HTTPigeon::Logger).to receive(:new)

        request = described_class.new(base_url: 'https://www.example.com', logger: custom_logger_klass.new) do |conn|
          conn.request :json
          conn.response :json
        end

        expect(HTTPigeon::Logger).not_to have_received(:new)
        expect(request.connection.builder.handlers).to include(HTTPigeon::Middleware::HTTPigeonLogger)
      end

      it 'does not set a custom :httpigeon_logger if provided and is not a type of httpigeon logger' do
        allow(HTTPigeon::Logger).to receive(:new)

        request = described_class.new(base_url: 'https://www.example.com', logger: Logger.new($stdout)) do |conn|
          conn.request :json
          conn.response :json
        end

        expect(HTTPigeon::Logger).not_to have_received(:new)
        expect(request.connection.builder.handlers).not_to include(HTTPigeon::Middleware::HTTPigeonLogger)
      end
    end

    context 'when a block is not given' do
      it 'sets the expected default headers' do
        allow(SecureRandom).to receive(:uuid).and_return('secure-random-uuid')

        test_table = [
          { # when auto generate request id is turned off
            auto_generate_request_id: false,
            request_headers: { 'Foo' => 'barzz' },
            included_headers: { 'Accept' => 'application/json', 'Foo' => 'barzz' }
          },
          { # when auto generate request id is turned on
            auto_generate_request_id: true,
            request_headers: { 'Foo' => 'barzz' },
            included_headers: { 'Accept' => 'application/json', 'X-Request-Id' => 'secure-random-uuid', 'Foo' => 'barzz' }
          }
        ]

        test_table.each do |test_case|
          allow(HTTPigeon).to receive(:auto_generate_request_id).and_return(test_case[:auto_generate_request_id])
          request = described_class.new(base_url: 'https://www.example.com', headers: test_case[:request_headers], event_type: 'event.type', log_filters: [:super_secret])

          expect(request.connection.headers.slice(*%w[Accept X-Request-Id Foo])).to eq(test_case[:included_headers])
        end
      end

      it 'uses the default logger if a custom logger is not provided' do
        allow(HTTPigeon::Logger).to receive(:new)

        request = described_class.new(base_url: 'https://www.example.com', event_type: 'event.type', log_filters: [:super_secret])

        expect(HTTPigeon::Logger).to have_received(:new).with(event_type: 'event.type', log_filters: [:super_secret])
        expect(request.connection.builder.handlers).to include(HTTPigeon::Middleware::HTTPigeonLogger)
      end

      it 'uses the custom if provided and is a type of httpigeon logger' do
        allow(HTTPigeon::Logger).to receive(:new)

        request = described_class.new(base_url: 'http://www.example.com', logger: custom_logger_klass.new)

        expect(HTTPigeon::Logger).not_to have_received(:new)
        expect(request.connection.builder.handlers).to include(HTTPigeon::Middleware::HTTPigeonLogger)
      end

      it 'uses the default logger if a custom logger is provided but is not a type of httpigeon logger' do
        allow(HTTPigeon::Logger).to receive(:new)

        request = described_class.new(base_url: 'https://www.example.com', logger: Logger.new($stdout))

        expect(HTTPigeon::Logger).to have_received(:new)
        expect(request.connection.builder.handlers).to include(HTTPigeon::Middleware::HTTPigeonLogger)
      end
    end
  end

  describe '#run' do
    subject(:run_request) { request.run(method: method, path: '/users', payload: { email: 'email@example.com' }) }

    let(:request) { described_class.new(base_url: 'https://www.example.com') }
    let(:logger_double) { instance_double(HTTPigeon::Logger, log: true) }

    before do
      allow(HTTPigeon::Logger).to receive(:new).and_return(logger_double)
      allow_any_instance_of(Faraday::Response).to receive(:body).and_return(response_body)

      run_request
    end

    context 'when it is not a read request' do
      let(:method) { :post }
      let(:response_body) { { response: 'body' }.to_json }

      it 'sets the content type header, makes the request, logs and returns parsed response' do
        request_env = request.response.env

        expect(request_env.request_headers['Content-Type']).to eq('application/json')
        expect(request_env.method).to eq(method)
        expect(request_env.request_body).to eq({ email: 'email@example.com' }.to_json)
        expect(logger_double).to have_received(:log).with(any_args)
        expect(run_request).to eq(JSON.parse(response_body).with_indifferent_access)
      end
    end

    context 'when it is a read request' do
      let(:method) { :get }
      let(:response_body) { { response: 'body' }.to_json }

      it 'sets the content type header, makes the request, logs and returns parsed response' do
        request_env = request.response.env

        expect(request_env.request_headers['Content-Type']).to be_nil
        expect(request_env.method).to eq(method)
        expect(request_env.request_body).to be_nil
        expect(logger_double).to have_received(:log).with(any_args)
        expect(run_request).to eq(JSON.parse(response_body).with_indifferent_access)
      end
    end
  end
end
