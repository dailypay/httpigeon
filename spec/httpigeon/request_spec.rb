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

      described_class.new(base_url: 'https://www.example.com', event_type: 'event.type', log_filters: [:super_secret])

      expect(HTTPigeon::Logger).to have_received(:new).with(event_type: 'event.type', log_filters: [:super_secret])
    end

    it 'uses the custom logger if one if provided' do
      allow(HTTPigeon::Logger).to receive(:new)

      described_class.new(base_url: 'http://www.example.com', logger: Logger.new($stdout))

      expect(HTTPigeon::Logger).not_to have_received(:new)
    end
  end

  describe '#run' do
    subject { request.run(method: method, path: '/users', payload: { email: 'email@example.com' }) }

    let(:request) { described_class.new(base_url: 'https://www.example.com') }
    let(:logger_double) { instance_double(HTTPigeon::Logger, log: true) }

    before do
      allow(HTTPigeon::Logger).to receive(:new).and_return(logger_double)
      allow_any_instance_of(Faraday::Response).to receive(:body).and_return(response_body)

      subject
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
        expect(subject).to eq(JSON.parse(response_body).with_indifferent_access)
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
        expect(subject).to eq(JSON.parse(response_body).with_indifferent_access)
      end
    end
  end
end
