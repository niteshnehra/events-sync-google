# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class SessionsController < ApplicationController
  def new
    redirect_to authorization_url, allow_other_host: true
  end

  def create
    code = params[:code]
    response = get_access_token(code)
    session[:access_token] = response['access_token']
    redirect_to events_path
  end

  def destroy
    session[:access_token] = nil
    redirect_to root_path
  end

  private

  def authorization_url
    uri = URI(GOOGLE_AUTH_URL)
    uri.query = URI.encode_www_form(
      client_id: GOOGLE_CLIENT_ID,
      redirect_uri: GOOGLE_REDIRECT_URI,
      response_type: 'code',
      # scope: 'https://www.googleapis.com/auth/calendar.readonly',
      scope: 'https://www.googleapis.com/auth/calendar',
      access_type: 'offline',
      include_granted_scopes: 'true'
    )
    uri.to_s
  end

  def get_access_token(code)
    uri = URI(GOOGLE_TOKEN_URL)
    response = Net::HTTP.post_form(uri, {
                                     code:,
                                     client_id: GOOGLE_CLIENT_ID,
                                     client_secret: GOOGLE_CLIENT_SECRET,
                                     redirect_uri: GOOGLE_REDIRECT_URI,
                                     grant_type: 'authorization_code'
                                   })
    JSON.parse(response.body)
  end
end
