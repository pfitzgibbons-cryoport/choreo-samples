require 'openssl'
require 'base64'
require 'aws-sdk-cognitoidentityprovider'
require 'inifile'

module AwsCognito
  class Authenticator
    attr_reader :username, :password

    def initialize(username:, password:)
      @username = username
      @password = password
    end

    # Executes the authentication flow against Cognito.
    # @return [Hash] A hash with `success: true` and the authentication `data` on success,
    #   or `success: false` and an `error` message on failure.
    def call
      puts "Authenticating user: #{username} with Cognito..."
      puts "User Pool ID: #{cognito_config[:user_pool_id]}"
      puts "Client ID: #{cognito_config[:client_id]}"
      puts "Auth Flow: ADMIN_USER_PASSWORD_AUTH"
      
      response = cognito_client.admin_initiate_auth(
        user_pool_id: cognito_config[:user_pool_id],
        client_id: cognito_config[:client_id],
        auth_flow: 'ADMIN_USER_PASSWORD_AUTH',
        auth_parameters: auth_parameters
      )
      
      if response && response.authentication_result
        puts "Authentication successful. Token received."
        { success: true, data: response.authentication_result }
      elsif response && response.challenge_name == 'NEW_PASSWORD_REQUIRED'
        puts "NEW_PASSWORD_REQUIRED challenge received. User needs to set a new password."
        { 
          success: false, 
          error: 'User needs to set a new password. Please reset the password for this user in AWS Cognito.', 
          code: 403,
          challenge: 'NEW_PASSWORD_REQUIRED'
        }
      else
        puts "Authentication response received but no authentication_result found."
        puts "Response details: #{response.inspect}"
        { success: false, error: 'Authentication succeeded but no token was returned.', code: 500 }
      end
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
      puts "NotAuthorizedException: #{e.message}"
      { success: false, error: 'Invalid username or password.', code: 401 }
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      puts "Cognito Service Error: #{e.class.name} - #{e.message}"
      { success: false, error: "AWS Cognito error: #{e.message}", code: 503 }
    rescue => e
      puts "Unexpected Authentication Error: #{e.class.name} - #{e.message}"
      puts e.backtrace.join("\n")
      { success: false, error: "Unexpected error: #{e.message}", code: 500 }
    end

    private

    def auth_parameters
      params = {
        'USERNAME' => username,
        'PASSWORD' => password
      }
      if cognito_config[:client_secret].to_s.strip != ''
        params['SECRET_HASH'] = calculate_secret_hash
      end
      params
    end

    def calculate_secret_hash
      message = username + cognito_config[:client_id]
      digest = OpenSSL::Digest.new('sha256')
      hmac = OpenSSL::HMAC.digest(digest, cognito_config[:client_secret], message)
      Base64.encode64(hmac).strip
    end

    def cognito_client
      @cognito_client ||= Aws::CognitoIdentityProvider::Client.new(client_config)
    end

    def client_config
      # Always use the development profile explicitly
      config = { 
        region: cognito_config[:region],
        profile: 'development'
      }
      
      # Debug output to verify profile being used
      puts "AWS SDK using profile: #{config[:profile]}"
      puts "AWS SDK region: #{config[:region]}"
      puts "AWS credentials path: #{ENV['AWS_CONFIG_FILE'] || '~/.aws/credentials'}"
      
      config
    end

    def cognito_config
      @cognito_config ||= {
        user_pool_id: ENV['AWS_COGNITO_USER_POOL_ID'],
        client_id: ENV['AWS_COGNITO_CLIENT_ID'],
        client_secret: ENV['AWS_COGNITO_CLIENT_SECRET'],
        region: ENV['AWS_COGNITO_REGION'],
        profile: ENV['AWS_COGNITO_PROFILE']
      }
    end
  end
end
