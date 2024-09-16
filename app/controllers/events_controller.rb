# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :set_event, only: %i[edit update destroy]
  before_action :check_google_authentication, only: [:sync_google_calendar_events]

  def index
    @events = Event.all
  end

  def sync_google_calendar_events
    begin
      events = google_calendar_service.fetch_events

      # Fetch all events from the database
      db_event_ids = Event.pluck(:event_id, :calendar_id).to_set
      google_event_ids = events.map { |event| [event[:event_id], event[:calendar_id]] }.to_set

      # Find events to delete
      events_to_delete = db_event_ids - google_event_ids
      events_to_delete.each do |event_id, calendar_id|
        Event.find_by(calendar_id:, event_id:)&.destroy
      end

      if events.present?
        events.each do |event_data|
          create_or_update_event(event_data)
        end
        flash[:notice] = 'Events synchronized successfully.'
      else
        flash[:alert] = 'No events found to synchronize.'
      end
    rescue StandardError => e
      flash[:alert] = "An error occurred while syncing events: #{e.message}"
    end

    redirect_to events_path
  end

  private

  def create_or_update_event(event_data)
    return if event_data.nil?

    required_keys = %i[calendar_id event_id summary description start_time end_time]
    missing_keys = required_keys - event_data.keys

    return if missing_keys.any?

    existing_event = Event.find_by(calendar_id: event_data[:calendar_id], event_id: event_data[:event_id])

    if existing_event
      existing_event.update!(
        summary: event_data[:summary],
        description: event_data[:description],
        start_time: event_data[:start_time],
        end_time: event_data[:end_time]
      )

    else
      Event.create!(
        calendar_id: event_data[:calendar_id],
        event_id: event_data[:event_id],
        summary: event_data[:summary],
        description: event_data[:description],
        start_time: event_data[:start_time],
        end_time: event_data[:end_time]
      )
    end
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:summary, :description, :start_time, :end_time)
  end

  def check_google_authentication
    access_token = session[:access_token]
    if access_token

      unless google_calendar_service.validate_token
        redirect_to auth_google_oauth2_path, alert: 'You need to authenticate first.'
      end
    else
      redirect_to auth_google_oauth2_path, alert: 'You need to authenticate first.'
    end
  end

  def google_calendar_service
    @google_calendar_service ||= GoogleCalendarService.new(session[:access_token])
  end
end
