# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'uri'
require 'json'

HOST = 'localhost'
PORTS = [3000, 3001, 3002]

# Internal API
get '/internal' do
  read_local(request.port).to_json
end

post '/internal' do
  data = JSON.parse(request.body.read)
  write_local(request.port, data)
  true
end

def read_local(port)
  file = "data-#{port}.json"
  if File.exists?(file)
    JSON.parse(File.read(file), symbolize_names: true)
  else
    {version: 0, kvs: {}, }
  end
end

def write_local(port, data)
  file = "data-#{port}.json"
  File.open(file, mode = 'w') { |f| JSON.dump(data, f) }
end

def sync(port)
  local_data = read_local(port)
  friend_hosts = PORTS.select { |p| p != port }
  error_count = 0
  friend_data = friend_hosts.map do |p|
    begin
      uri = URI.parse("http://#{HOST}:#{p}/internal")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      if response.kind_of? Net::HTTPSuccess
        JSON.parse(response.body, symbolize_names: true)
      else
        error_count += 1
        nil
      end
    rescue => e
      error_count += 1
      nil
    end
  end

  if error_count > 1
    false
  else
    friend_data.each do |d|
      if !d.nil? && d[:version] > local_data[:version]
        local_data = d
      end
    end
    write_local(port, local_data)
    true
  end
end

get '/:key' do
  port = request.port
  key = params['key']

  status 500 unless sync(port)

  data = read_local(port)
  return data[:kvs][key.to_sym]
end

post '/:key' do
  (key, value) = [params['key'], request.body.read]

  port = request.port
  status 500 unless sync(port)

  data = read_local(port)
  data[:version] += 1
  data[:kvs][key.to_sym] = value
  write_local(port, data)

  error_count = 0

  PORTS.select { |p| p != port }.each do |p|
    begin
      uri = URI.parse("http://#{HOST}:#{p}/internal")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = data.to_json
      response = http.request(request)
      error_count += 1 unless response.kind_of? Net::HTTPSuccess
    rescue => e
      p e
      error_count += 1
    end
  end

  if error_count > 1
    status 500
  else
    true
  end
end
