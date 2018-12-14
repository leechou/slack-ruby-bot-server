require 'spec_helper'

describe SlackRubyBotServer::Ping do
  let(:team) { SlackRubyBotServer::Team.new(token: 'token') }
  let(:options) { {} }
  let(:server) { SlackRubyBotServer::Server.new({ team: team }.merge(options)) }
  let(:client) { server.send(:client) }

  subject do
    server.send(:create_ping)
  end

  context 'with defaults' do
    before do
      allow(subject.wrapped_object).to receive(:every).and_yield
      # allow_any_instance_of(Async::Task).to receive(:sleep)
    end

    it 'defaults retry count' do
      expect(subject.send(:retry_count)).to eq 2
    end

    it 'calculates retries left' do
      expect(subject.send(:retries_left)).to eq 2
    end

    it 'defaults ping interval' do
      expect(subject.send(:ping_interval)).to eq 60
    end

    it 'checks for connection' do
      expect(subject.wrapped_object).to receive(:check!)
      # expect(subject).to receive(:check!).and_return(false)
      subject.start!
    end

    context 'after a failed check' do
      before do
        allow(subject.wrapped_object).to receive(:online?).and_return(false)
        subject.start!
        # allow(subject).to receive(:online?).and_return(false)
        # subject.send(:check!)
      end

      it 'decrements retries left' do
        expect(subject.send(:retries_left)).to eq 1
      end

      it 'sets error count' do
        expect(subject.send(:error_count)).to eq 1
      end

      context 'after a successful check' do
        before do
          allow(subject.wrapped_object).to receive(:online?).and_return(true)
          subject.start!
          # allow(subject).to receive(:online?).and_return(true)
          # subject.send(:check!)
        end

        it 're-increments retries left' do
          expect(subject.send(:retries_left)).to eq 2
        end

        it 'resets error count' do
          expect(subject.send(:error_count)).to eq 0
        end
      end

      context 'after two more failed checks' do
        before do
          allow(subject).to receive(:online?).and_return(false).twice
          2.times { subject.send(:check!) }
        end

        it 'does not decrement retries left below zero' do
          expect(subject.send(:retries_left)).to eq 0
        end

        it 'sets error count' do
          expect(subject.send(:error_count)).to eq 3
        end
      end
    end

    it 'terminates the ping worker after account_inactive' do
      allow(subject.wrapped_object).to receive(:online?).and_raise('account_inactive')
      expect(subject.wrapped_object).to receive(:terminate)
      # allow(subject).to receive(:online?).and_raise('account_inactive')
      # subject.start!
    end

    it 'restarts and terminates after a number of retries' do
      allow(subject.wrapped_object).to receive(:online?).and_return(false)
      expect(subject.wrapped_object).to receive(:terminate)
      3.times { subject.start! }
      # allow(subject).to receive(:online?).and_return(false)
      # expect(subject).to receive(:check!).exactly(3).times.and_call_original
      # expect(subject).to receive(:restart!).and_call_original
      # expect(subject).to receive(:close_connection).and_call_original
      # expect(subject).to receive(:close_driver).and_call_original
      # expect(subject).to receive(:emit_close).and_call_original
      # subject.start!
    end

    it 'does not terminate upon a failed restart' do
      allow(subject).to receive(:online?).and_return(false)
      allow(subject).to receive(:close_connection) { raise 'error closing connection' }
      expect(subject).to receive(:check!).exactly(3).times.and_call_original
      expect(subject).to receive(:check!).and_return(false)
      subject.start!
    end
  end

  context 'with options' do
    context 'ping interval' do
      let(:options) { { ping: { ping_interval: 42 } } }

      it 'is used' do
        # expect_any_instance_of(Async::Task).to receive(:sleep).with(42)
        expect(subject.send(:ping_interval)).to eq 42
        expect(subject.wrapped_object).to receive(:every).with(42)
        # expect(subject).to receive(:check!).and_return(false)
        subject.start!
      end
    end

    context 'retry count' do
      let(:options) { { ping: { retry_count: 42 } } }

      it 'is set' do
        expect(subject.send(:retry_count)).to eq 42
      end

      it 'adjusts retries left' do
        expect(subject.send(:retries_left)).to eq 42
      end
    end

    context 'enabled' do
      context 'nil' do
        let(:options) { { ping: { enabled: nil } } }

        it 'does not create a worker' do
          expect(subject).to be_nil
        end
      end

      context 'false' do
        let(:options) { { ping: { enabled: false } } }

        it 'does not create a worker' do
          expect(subject).to be_nil
        end
      end

      context 'true' do
        let(:options) { { ping: { enabled: true } } }

        it 'creates a worker' do
          expect(subject).to_not be_nil
        end
      end
    end
  end
end
