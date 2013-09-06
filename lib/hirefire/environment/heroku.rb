# encoding: utf-8

require 'heroku-api'

module HireFire
  module Environment
    class Heroku < Base
      TOO_OLD = ENV['HIREFIRE_TOO_OLD'] ? ENV['HIREFIRE_TOO_OLD'].to_i || 20

      @@ps_cache = {}

      private

      def too_old?(ts)
        return Time.now - ts > TOO_OLD
      end

      def get_worker_count(app_name)
        data = @@ps_cache(app_name)

        return data[:worker_count] if !too_old?(data[:ts])

        worker_count = client.get_ps(app_name).body.select {|p| p['process'] =~ /worker.[0-9]+/}.length
        @@ps_cache[app_name] = { :worker_count => worker_count, :ts => Time.now }

        return worker_count
      end

      def set_worker_count(app_name, amount)
        val = client.post_ps_scale(app_name, "worker", amount)
        @@ps_cache[app_name] = { :worker_count => amount, :ts => Time.now }
        return val
      end

      def workers(amount = nil)

        app_name = HireFire.configuration.app_name
        #puts "HIREFIRE FOR APP #{app_name}"

        return get_worker_count(app_name) if amount.nil?

        # client.set_workers(app_name], amount)

        return set_worker_count(app_name, amount)

      rescue Exception
        HireFire::Logger.message("Worker query request failed with #{ $!.class.name } #{ $!.message }")
        nil
      end

      def client
        @client ||= ::Heroku::API.new # will pick up api_key from configs
      end

    end
  end
end
