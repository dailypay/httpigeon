require 'spec_helper'

describe HTTPigeon::Middleware::HTTPigeonLogger do
  subject(:middleware) { described_class.new(app, logger) }

  let(:app) { ->(env) { env } }
  let(:logger) { instance_double(HTTPigeon::Logger, on_request_start: nil, on_request_finish: nil, log: nil) }
  let(:env) { Faraday::Env.new }

  describe '#call' do
    context 'when the request succeeds' do
      it 'logs on completion and returns the response' do
        allow(app).to receive(:call).and_return(Faraday::Response.new(env))

        middleware.call(env)

        expect(logger).to have_received(:on_request_start)
        expect(logger).to have_received(:on_request_finish)
        expect(logger).to have_received(:log).with(env)
      end
    end

    context 'when the request raises' do
      let(:error) { StandardError.new('boom') }

      before { allow(app).to receive(:call).and_raise(error) }

      it 'logs the error and re-raises it' do
        expect { middleware.call(env) }.to raise_error(error)

        expect(logger).to have_received(:on_request_finish)
        expect(logger).to have_received(:log).with(env, { error: error })
      end
    end
  end
end
