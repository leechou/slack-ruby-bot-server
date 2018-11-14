require 'spec_helper'

describe SlackRubyBotServer::Api::Endpoints::StatusEndpoint do
  include SlackRubyBotServer::Api::Test::EndpointTest

  before do
    allow_any_instance_of(SlackRubyBotServer::Team).to receive(:ping!).and_return(ok: 1)
  end

  context 'status' do
    it 'returns a status' do
      status = client.status
      expect(status.teams_count).to eq 0
    end

    context 'with a team' do
      let!(:team) { Fabricate(:team, active: false) }
      it 'returns a status with ping' do
        status = client.status
        expect(status.teams_count).to eq 1
        ping = status.ping
        expect(ping['ok']).to eq 1
      end
    end
  end
end
