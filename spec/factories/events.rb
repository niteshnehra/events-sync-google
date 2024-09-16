# spec/factories/events.rb
FactoryBot.define do
  factory :event do
    calendar_id { "cal_#{Faker::Number.number(digits: 2)}" }
    event_id { "event_#{Faker::Number.number(digits: 2)}" }
    summary { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    start_time { Faker::Time.forward(days: 5, period: :morning) }
    end_time { Faker::Time.forward(days: 5, period: :afternoon) }
  end
end
