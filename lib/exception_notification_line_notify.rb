require "exception_notification_line_notify/version"

module ExceptionNotificationLineNotify
  module ExceptionNotifier
    class LineNotifier
      def initialize args = {}
        args = args.symbolize_keys

        @line_notify_token = args.fetch(:line_notify_token, nil)

      end

      def call(exception, options={})
        require 'rest-client'
        @request = ActionDispatch::Request.new(options[:env])
        @backtrace = exception.backtrace.first
        @exception_message = exception.message

        @request_section = {
          parameters: @request.filtered_parameters.inspect,
          method: @request.request_method,
          ip: @request.remote_ip,
          root: Rails.root.to_s,
        }.map{|k, v| "[#{k}] \n#{v}"}.join("\n")

        @session_section = @request.session.to_hash.inspect
        

        @message = %Q(
          \n #{@request.url}
          \n #{@backtrace}
          \n======Request=====
          \n#{@request_section}
          \n======Session=====
          \n#{@session_section}
        )

        if @line_notify_token
          begin
            @response = RestClient.post 'https://notify-api.line.me/api/notify', {message: @message}, { :Authorization => "Bearer #{@line_notify_token}"}
          rescue => e
            puts e
          end
        end
      end
    end
  end
end
