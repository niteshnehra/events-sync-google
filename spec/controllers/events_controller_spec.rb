# spec/controllers/events_controller_spec.rb
require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:user) { create(:user) }  # Assuming you're using Devise or similar
  let(:event) { create(:event) }
  let(:google_events) do
    [
      {
        event_id: 'event_1',
        calendar_id: 'cal_1',
        summary: 'Test Event 1',
        description: 'Description 1',
        start_time: '2023-09-15T10:00:00Z',
        end_time: '2023-09-15T12:00:00Z'
      },
      {
        event_id: 'event_2',
        calendar_id: 'cal_2',
        summary: 'Test Event 2',
        description: 'Description 2',
        start_time: '2023-09-16T10:00:00Z',
        end_time: '2023-09-16T12:00:00Z'
      }
    ]
  end

  let(:mock_google_calendar_service) { double('GoogleCalendarService', fetch_events: google_events, validate_token: true) }

  before do
    allow(controller).to receive(:google_calendar_service).and_return(mock_google_calendar_service)
    allow(controller).to receive(:check_google_authentication).and_return(true)
    session[:access_token] = 'dummy_token' # Simulate a valid token
  end

  describe 'GET #index' do
    it 'sync all events to @events' do
      event = create(:event)
      get :index
      expect(assigns(:events)).to eq([event])
    end
  end

  describe 'POST #sync_google_calendar_events' do
    context 'with valid Google events' do
      it 'fetches events from Google Calendar' do
        expect(mock_google_calendar_service).to receive(:fetch_events)
        post :sync_google_calendar_events
      end

      it 'creates new events if they do not exist' do
        expect {
          post :sync_google_calendar_events
        }.to change(Event, :count).by(google_events.size)
      end

      it 'updates existing events' do
        existing_event = create(:event, calendar_id: 'cal_1', event_id: 'event_1', summary: 'Old Summary')
        post :sync_google_calendar_events
        expect(existing_event.reload.summary).to eq('Test Event 1')
      end

      it 'deletes events no longer in Google Calendar' do
        event_to_delete = create(:event, calendar_id: 'cal_3', event_id: 'event_3')
        expect {
          post :sync_google_calendar_events
        }.to change(Event, :count).by(google_events.size - 1) # 1 existing event should be deleted
      end

      it 'sets a success flash message' do
        post :sync_google_calendar_events
        expect(flash[:notice]).to eq('Events synchronized successfully.')
      end

      it 'redirects to events path' do
        post :sync_google_calendar_events
        expect(response).to redirect_to(events_path)
      end
    end

    context 'when no events are returned from Google' do
      before do
        allow(mock_google_calendar_service).to receive(:fetch_events).and_return([])
      end

      it 'does not create or update any events' do
        expect {
          post :sync_google_calendar_events
        }.not_to change(Event, :count)
      end

      it 'sets an alert flash message' do
        post :sync_google_calendar_events
        expect(flash[:alert]).to eq('No events found to synchronize.')
      end
    end

    context 'when an error occurs during sync' do
      before do
        allow(mock_google_calendar_service).to receive(:fetch_events).and_raise(StandardError.new('Some error'))
      end

      it 'sets an error flash message' do
        post :sync_google_calendar_events
        expect(flash[:alert]).to eq('An error occurred while syncing events: Some error')
      end

      it 'redirects to events path' do
        post :sync_google_calendar_events
        expect(response).to redirect_to(events_path)
      end
    end
  end

  describe 'Authentication' do
    context 'when the user is not authenticated' do
      before do
        allow(controller).to receive(:check_google_authentication).and_call_original
        session[:access_token] = nil # Simulate no access token
      end

      it 'redirects to Google authentication path' do
        post :sync_google_calendar_events
        expect(response).to redirect_to(auth_google_oauth2_path)
        expect(flash[:alert]).to eq('You need to authenticate first.')
      end
    end
  end
end
