# frozen_string_literal: true

# app/services/google_calendar_service.rb
require 'net/http'
require 'uri'
require 'json'

class GoogleCalendarService
  API_URL = 'https://www.googleapis.com/calendar/v3'

  def initialize(access_token)
    @access_token = access_token
  end

  def fetch_events
    calendars = fetch_calendars
    calendars.flat_map do |calendar|
      fetch_events_from_calendar(calendar['id'])
    end
  end

  def delete_event(calendar_id, event_id)
    uri = URI("#{API_URL}/calendars/#{calendar_id}/events/#{event_id}")
    request = Net::HTTP::Delete.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    response.is_a?(Net::HTTPSuccess)
  end

  def validate_token
    uri = URI('https://www.googleapis.com/oauth2/v3/tokeninfo')
    uri.query = URI.encode_www_form({ access_token: @access_token })

    response = Net::HTTP.get_response(uri)
    token_info = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess) && token_info['error'].nil?
      true
    else
      false
    end
  end

  private

  def fetch_calendars
    fetch_from_api('/users/me/calendarList')
  end

  def fetch_events_from_calendar(calendar_id)
    events = fetch_from_api("/calendars/#{calendar_id}/events")
    return unless events

    events.map do |event|
      {
        calendar_id:,
        event_id: event['id'],
        summary: event['summary'],
        description: event['description'],
        start_time: event.dig('start', 'dateTime'),
        end_time: event.dig('end', 'dateTime')
      }
    end
  end

  def fetch_from_api(path)
    uri = URI("#{API_URL}#{path}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    return [] unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['items'] || []
  end
end
