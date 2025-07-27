require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/json'
require 'json'
require 'dotenv/load' if File.exist?('.env')

# Load the authenticator
require_relative 'lib/aws_cognito/authenticator'

configure do
  # Configure Sinatra
  set :port, ENV['PORT'] || 8080
  set :bind, '0.0.0.0'
  set :environment, ENV['RACK_ENV'] || 'development'
  # Enable JSON request body parsing
  set :show_exceptions, :after_handler
  enable :logging
end

# Handle JSON parsing errors
error JSON::ParserError do
  status 400
  json error: 'Invalid JSON format in request body'
end

get '/hello' do
  'hello, world'
end

# AWS Cognito Authentication Endpoint
post '/auth' do
  # Parse request body as JSON
  request_payload = JSON.parse(request.body.read) rescue {}
  
  # Extract username and password from request
  auth_data = request_payload['auth'] || {}
  username = auth_data['username'] || request_payload['username']
  password = auth_data['password'] || request_payload['password']
  
  # Validate required parameters
  if username.nil? || username.empty? || password.nil? || password.empty?
    status 400
    return json error: 'Username and password are required.'
  end
  
  # Authenticate against AWS Cognito
  result = AwsCognito::Authenticator.new(username: username, password: password).call
  
  if result[:success] && result[:data] && result[:data].id_token
    status 200
    json id_token: result[:data].id_token
  else
    status result[:code] || 401
    error_message = result[:error] || 'Authentication failed. No token returned.'
    json error: error_message
  end
end
