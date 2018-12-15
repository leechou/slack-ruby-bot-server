require_relative 'ext/slack-ruby-bot/client'

module SlackRubyBotServer
  class Server < SlackRubyBot::Server
    attr_accessor :team

    def initialize(attrs = {})
      attrs = attrs.dup
      @team = attrs.delete(:team)
      @ping_options = attrs.delete(:ping) || {}
      raise 'Missing team' unless @team

      secret_key = ENV['IDSEED']
      iv = ENV['SLACK_TOKEN_IV'].unpack("m").first
      token = Encryptor.decrypt(@team.token.unpack("m").first, algorithm: "aes-256-gcm", key: secret_key, iv: iv)

      attrs[:token] = token
      super(attrs)
      open!
    end

    def restart!(wait = 1)
      # when an integration is disabled, a live socket is closed, which causes the default behavior of the client to restart
      # it would keep retrying without checking for account_inactive or such, we want to restart via service which will disable an inactive team
      logger.info "#{team.name}: socket closed, restarting ..."
      SlackRubyBotServer::Service.instance.restart! team, self, wait
      open!
    end

    private

    attr_reader :ping_options

    def create_ping
      return unless !ping_options.key?(:enabled) || ping_options[:enabled]
      SlackRubyBotServer::Ping.new(client, ping_options)
    end

    def open!
      client.owner = team
      client.on :open do |_event|
        worker = create_ping
        worker.start! if worker
      end
    end
  end
end
