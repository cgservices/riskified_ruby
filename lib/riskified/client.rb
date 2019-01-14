require "faraday"
require "faraday_middleware"
require "openssl"
require 'json'

require 'riskified/configuration'

module Riskified
  class Client
    
    SANDBOX_URL = "https://sandbox.riskified.com".freeze
    LIVE_URL = "https://wh.riskified.com".freeze
    
    def checkout_create(body)
      post_request("/api/checkout_create", body)
    end
    
    def update(body)
      post_request("/api/update", body)
    end
    
    def checkout_denied(body)
      post_request("/api/checkout_denied", body)
    end  
    
    def cancel(body)
      post_request("/api/cancel", body)
    end
    
    def refund(body)
      post_request("/api/refund", body)  
    end    

    private
    
    def base_url
      Riskified.config.sandbox_mode == true ? SANDBOX_URL : LIVE_URL
    end

    def establish_connection(body)
      @connection ||= Faraday.new(base_url) do |connection|
        connection.headers = {
          "Content-Type": "application/json",
          "ACCEPT": "application/vnd.riskified.com; version=2",
          "X-RISKIFIED-SHOP-DOMAIN": Riskified.config.shop_domain,
          "X-RISKIFIED-HMAC-SHA256": calc_hmac(body)
        }
        connection.request :json
        connection.adapter Faraday.default_adapter
      end
    end
    
    def calc_hmac(body)
      OpenSSL::HMAC.hexdigest('SHA256', Riskified.config.auth_token, body.to_json)
    end

    def post_request(endpoint, params={})
      establish_connection(params)
      
      response = @connection.public_send(:post, endpoint, params)
      parsed_response = JSON.parse(response.body)
      
      if response_successful?(response)
        parsed_response 
      else
        { status: response.status, response: response.body }
      end
    end

    def response_successful?(response)
      response.status == 200 || 201
    end
  end
end
