require 'spec_helper'

describe HTTPigeon::Request do
  describe '.get' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/http/200/read-that'
      query = { q: 'John' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_call_original
      response = described_class.get(endpoint, query, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ "message" => "read-that", "status" => 200 })
      expect(response.raw_response).to be_a(Faraday::Response)
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
    end
  end

  describe '.post' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/http/202/wrote-this'
      payload = { firstName: 'John', lastName: 'Doe' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_call_original
      response = described_class.post(endpoint, payload, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ "message" => "wrote-this", "status" => 202 })
      expect(response.raw_response).to be_a(Faraday::Response)
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
    end
  end

  describe '.put' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/http/202/changed-this'
      payload = { firstName: 'John', lastName: 'Doe' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_call_original
      response = described_class.put(endpoint, payload, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ "message" => "changed-this", "status" => 202 })
      expect(response.raw_response).to be_a(Faraday::Response)
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
    end
  end

  describe '.delete' do
    it 'makes request with expected arguments' do
      endpoint = 'https://dummyjson.com/http/200/deleted-that'
      query = { q: 'John' }
      event_type = 'some.event'
      headers = { 'Foo' => 'Barzzz' }

      allow(described_class).to receive(:new).and_call_original
      response = described_class.delete(endpoint, query, headers, event_type)

      expect(response).to be_a(HTTPigeon::Response)
      expect(response.parsed_response).to eq({ "message" => "deleted-that", "status" => 200 })
      expect(response.raw_response).to be_a(Faraday::Response)
      expect(described_class).to have_received(:new).with(base_url: endpoint, headers: headers, event_type: event_type, log_filters: [])
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
        request = described_class.new(base_url: 'https://www.example.com', headers: { 'Foo' => 'barzz' })

        expect(request.connection.headers.slice(*%w[Accept Foo])).to eq({ 'Accept' => 'application/json', 'Foo' => 'barzz' })
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
        request = described_class.new(base_url: 'https://www.example.com', headers: { 'Foo' => 'barzz' })

        expect(request.connection.headers.slice(*%w[Accept Foo])).to eq({ 'Accept' => 'application/json', 'Foo' => 'barzz' })
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

    context 'when circuit breaker is enabled' do
      before do
        allow(HTTPigeon).to receive(:mount_circuit_breaker).and_return(true)
        allow(HTTPigeon::CircuitBreaker::Fuse).to receive(:from_options).and_call_original
      end

      it 'sets the circuit breaker middleware' do
        request = described_class.new(base_url: 'https://www.example.com', headers: { 'Foo' => 'barzz' })

        expect(request.connection.builder.handlers).to include(HTTPigeon::Middleware::CircuitBreaker)
      end
    end
  end

  describe '#run' do
    subject(:run_request) { request.run(method: method, path: '/users', payload: { email: 'email@example.com' }) }

    let(:request) { described_class.new(base_url: 'https://www.example.com') }
    let(:logger_double) { instance_double(HTTPigeon::Logger, log: true) }

    before do
      allow(SecureRandom).to receive(:uuid).and_return('request-uuid')
      allow(HTTPigeon::Logger).to receive(:new).and_return(logger_double)
      allow_any_instance_of(Faraday::Response).to receive(:body).and_return(response_body)
      allow_any_instance_of(Faraday::Response).to receive(:headers).and_return(response_headers)
      allow(request.fuse).to receive(:execute).and_call_original
    end

    context 'when circuit breaker is disabled' do
      let(:method) { :post }
      let(:response_body) { { response: 'body' }.to_json }
      let(:response_headers) { { 'content-type' => 'application/json' } }

      before { run_request }

      context 'when it is not a read request' do
        it 'runs the request without a fuse' do
          expect(request.fuse).not_to have_received(:execute)
        end

        it 'sets the request headers, makes the request, logs and returns parsed response' do
          request_env = request.response.env

          expect(request_env.request_headers['Content-Type']).to eq('application/json')
          expect(request_env.request_headers['X-Request-Id']).to eq('request-uuid')
          expect(request_env.method).to eq(method)
          expect(request_env.request_body).to eq({ email: 'email@example.com' }.to_json)
          expect(logger_double).to have_received(:log).with(any_args)
          expect(run_request).to eq(JSON.parse(response_body).with_indifferent_access)
        end
      end

      context 'when it is a read request' do
        let(:method) { :get }
        let(:response_body) { { response: 'body' }.to_json }

        it 'runs the request without a fuse' do
          expect(request.fuse).not_to have_received(:execute)
        end

        it 'sets the request headers, makes the request, logs and returns parsed response' do
          request_env = request.response.env

          expect(request.fuse).not_to have_received(:execute)
          expect(request_env.request_headers['Content-Type']).to be_nil
          expect(request_env.request_headers['X-Request-Id']).to eq('request-uuid')
          expect(request_env.method).to eq(method)
          expect(request_env.request_body).to be_nil
          expect(logger_double).to have_received(:log).with(any_args)
          expect(run_request).to eq(JSON.parse(response_body).with_indifferent_access)
        end
      end
    end

    context 'when circuit breaker is enabled' do
      let(:response_body) { { response: 'body' }.to_json }
      let(:method) { :get }
      let(:response_headers) { { 'content-type' => 'application/json' } }

      before do
        allow(HTTPigeon).to receive(:mount_circuit_breaker).and_return(true)

        run_request
      end

      it 'runs the request with a fuse' do
        request_env = request.response.env

        expect(request.fuse).to have_received(:execute)
        expect(request.fuse.success_count).to eq(1)
        expect(request_env.request_headers['Content-Type']).to be_nil
        expect(request_env.request_headers['X-Request-Id']).to eq('request-uuid')
        expect(request_env.method).to eq(method)
        expect(request_env.request_body).to be_nil
        expect(logger_double).to have_received(:log).with(any_args)
        expect(request.response.parsed_response).to eq(JSON.parse(response_body).with_indifferent_access)
      end
    end

    describe 'response parsing' do
      let(:method) { :get }

      test_cases = [
        {
          description: 'when the response is a json object',
          response_body: '{ "response": "body" }',
          expected_parsed_response: { response: 'body' }.with_indifferent_access,
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is an array',
          response_body: '["foo"]',
          expected_parsed_response: ['foo'],
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is nested array',
          response_body: '[["foo"], ["bar"]]',
          expected_parsed_response: [['foo'], ['bar']],
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is nested json objects',
          response_body: '{ "response": { "inner": "object" } }',
          expected_parsed_response: { response: { inner: 'object' }.with_indifferent_access }.with_indifferent_access,
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is json objects inside an array',
          response_body: '[{ "foo": "bar" }, { "baz": "qux" }]',
          expected_parsed_response: [{ foo: 'bar' }.with_indifferent_access, { baz: 'qux' }.with_indifferent_access],
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is arrays inside a json object',
          response_body: '{ "response": ["foo", "bar"] }',
          expected_parsed_response: { response: ['foo', 'bar'] }.with_indifferent_access,
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is a truly absurd json object',
          response_body: '[{"foo":"bar"},1,"foobar",true,null,[{"inner":"object"},1,null,[]]]',
          expected_parsed_response: [{ foo: "bar" }.with_indifferent_access, 1, "foobar", true, nil, [{ inner: "object" }.with_indifferent_access, 1, nil, []]],
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is invalid json',
          response_body: 'invalid json',
          expected_parsed_response: 'invalid json',
          headers: { 'content-type' => 'application/json' }
        },
        {
          description: 'when the response is a pdf',
          response_body: File.binread('spec/test-image.pdf'),
          expected_parsed_response: File.binread('spec/test-image.pdf'),
          headers: { 'content-type' => 'application/pdf' }
        }
      ]

      test_cases.each do |test_case|
        context test_case[:description] do
          let(:response_body) { test_case[:response_body] }
          let(:response_headers) { test_case[:headers] }

          it 'parses the response appropriately' do
            expect(run_request).to eq(test_case[:expected_parsed_response])
          end
        end
      end
    end
  end
end
