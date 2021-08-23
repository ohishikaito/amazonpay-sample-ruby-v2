#!/usr/bin/env ruby

=begin
ここにコメントがあったけど, /libs/README.mdに移した！
=end

# gem 'openssl' if RUBY_VERSION < '2.4'
require 'openssl'

require 'net/http'
require 'time'
require 'json'
require 'base64'

class AmazonPayClient

    def initialize config
        @helper = Helper.new config
    end

    def generate_button_signature payload = ''
        @helper.sign(payload.is_a?(String) ? payload : JSON.generate(payload))
    end

    def api_call url_fragment, method, payload: '', headers: {}, query_params: {}
        query = @helper.to_query query_params
        uri = URI.parse(@helper.base_url + url_fragment + (query ? "?#{query}" : ''))
        request = @helper.http_method(method).new(uri)
        request.body = payload.is_a?(String) ? payload : JSON.generate(payload)

        signed_headers = @helper.signed_headers(method, uri, request.body, headers, query)
        signed_headers.each { |k, v| request[k] = v }

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
        end
    end

    API_VERSION = "v2"
    API_ENDPOINTS = {
        'na' => 'pay-api.amazon.com',
        'eu' => 'pay-api.amazon.eu',
        'jp' => 'pay-api.amazon.jp'
    }
    METHOD_TYPES = {
        'GET' => Net::HTTP::Get,
        'POST' => Net::HTTP::Post,
        'PUT' => Net::HTTP::Put,
        'PATCH' => Net::HTTP::Patch,
        'DELETE' => Net::HTTP::Delete
    }
    HASH_ALGORITHM = "SHA256"
    AMAZON_SIGNATURE_ALGORITHM = "AMZN-PAY-RSASSA-PSS"

    class Helper
        attr_reader :base_url

        def initialize config
            @region = get :region, config
            @public_key_id = get :public_key_id, config
            @private_key = get :private_key, config
            @base_url = "https://#{endpoint}/#{get(:sandbox, config) ? 'sandbox' : 'live'}/#{API_VERSION}/"
        end

        def get key, config
            config[key] || config[key.to_s]
        end

        def endpoint
            API_ENDPOINTS[@region] || raise(ArgumentError, "Unknown region, '#{@region}'. The region should be one of follows: #{API_ENDPOINTS.keys}.")
        end

        def http_method method
            METHOD_TYPES[method] || raise(ArgumentError, "Unknown HTTP method, '#{method}'. The HTTP method should be one of follows: #{METHOD_TYPES.keys}.")
        end

        def signed_headers(method, uri, payload, user_headers, query)
            payload = '' if uri.path.include?('account-management/v2/accounts')

            headers = Hash[user_headers.map{|k, v| [k.to_s, v.gsub(/\s+/, ' ')]}]
            headers['accept'] = headers['content-type'] = 'application/json'
            headers['x-amz-pay-region'] = @region
            headers['x-amz-pay-date'] = formatted_timestamp
            headers['x-amz-pay-host'] = uri.host

            canonical_headers = Hash[ headers.map{|k, v| [k.to_s.downcase, v]}.sort_by { |kv| kv[0] } ]
            canonical_header_names = canonical_headers.keys.join(';')
            canonical_request = <<~EOS.chomp
                #{method}
                #{uri.path}
                #{query}
                #{canonical_headers.map{|k, v| "#{k}:#{v}"}.join("\n")}

                #{canonical_header_names}
                #{hex_and_hash(payload)}
            EOS
            signed_headers = "SignedHeaders=#{canonical_header_names}, Signature=#{sign canonical_request}"
            headers['authorization'] = "#{AMAZON_SIGNATURE_ALGORITHM} PublicKeyId=#{@public_key_id}, #{signed_headers}"

            headers
        end

        def sign string_to_sign
            hashed_canonical_request = "#{AMAZON_SIGNATURE_ALGORITHM}\n#{hex_and_hash(string_to_sign)}"
            rsa = OpenSSL::PKey::RSA.new @private_key
            Base64.strict_encode64(rsa.sign_pss(HASH_ALGORITHM, hashed_canonical_request, salt_length: 20, mgf1_hash: HASH_ALGORITHM))
        end

        def to_query(query_params)
            query_params.map{|k, v| [url_encode(k.to_s), url_encode(v)]}.sort_by{|kv| kv[0]}.map{|kv| "#{kv[0]}=#{kv[1]}"}.join('&')
        end

        def hex_and_hash(data)
            Digest::SHA256.hexdigest(data)
        end

        def formatted_timestamp
            Time.now.utc.iso8601.split(/[-,:]/).join
        end

        def url_encode(value)
            URI::encode(value).gsub('%7E', '~')
        end
    end
end
