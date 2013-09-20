require 'helper'

# http://sendgrid.com/docs/API_Reference/Webhooks/event.html

class EventTest < TestCase

  def setup
    @events = []
    Gridhook.config.event_processor = proc do |event|
      @events << event
    end
  end

  test 'parsing a single incoming JSON object' do
    obj = { email: 'foo@bar.com', timestamp: Time.now.to_i, event: 'delivered' }
    process obj.to_json
    assert_equal 1, @events.size
    assert_equal 'delivered', @events.first.name
  end

  # for when sendgrid fix their JSON batch requests
  test 'parsing incoming (valid) JSON in batches' do
    obj = [
      { email: 'foo@bar.com', timestamp: Time.now.to_i, event: 'delivered' },
      { email: 'foo@bar.com', timestamp: Time.now.to_i, event: 'open' }
    ]
    process obj.to_json
    assert_equal 2, @events.size
  end

  test 'ensure we fallback to request parameters if invalid JSON found in body' do
    process('email=test@gmail.com&arg2=2&arg1=1&category=testing&event=processed',
      { :email => 'test@gmail.com', :arg2 => '2', :arg1 => '1', :category => 'testing',
        :event => 'processed', :controller => 'sendgrid', :action => 'receive'})
    assert_equal 1, @events.size
    assert_equal 'processed', @events.first.event
  end

  private

  def process(str, params = {})
    Gridhook::Event.process(str, params)
  end

end