require 'ui_spec_helper'

describe 'App UI' do
  include Rack::Test::Methods

  def app
    @app
  end

  before do
    @app = HttpSim.build_app do
      configure_endpoint 'GET', '/endpoint', 'Hi!', 200, {'X-CUSTOM-HEADER' => 'easy as abc', 'CONTENT-TYPE' => 'application/json'}

      configure_dynamic_endpoint 'GET', '/dynamic', ->(req) {
        [201, {'X-CUSTOM-HEADER' => '123'}, 'Howdy!']
      }

      configure_matcher_endpoint 'POST', '/matcher', {
        /key1/ => [202, {'X-CUSTOM-HEADER' => 'accepted'}, 'Yo!'],
        /key2/ => [203, {'X-CUSTOM-HEADER' => 'I got this elsewhere'}, 'Yo!'],
      }
    end
    Capybara.app = @app
  end

  it 'has a view of all matchers' do
    visit '/'
    expect(page).to have_content '/endpoint'
    expect(page).to have_content '/dynamic'
    expect(page).to have_content '/matcher'

    expect(page).to have_css 'tr', text: 'key1'
    expect(page).to have_css 'tr', text: 'key2'
  end

  it 'does not show the overriden matchers' do
    put '/response/endpoint', {body: 'new body', method: 'get'}.to_json, 'CONTENT_TYPE' => 'application/json'

    visit '/'

    expect(page).to have_css 'tr', text: '/endpoint', count: 1
  end

  it 'can update the matcher' do
    visit '/'

    click_on '/endpoint'

    expect(page).to have_field 'Status code', with: 200
    expect(page).to have_field 'Response body', with: "Hi!"
    fill_in 'Status code', with: 202
    fill_in 'Response body', with: 'New UI Body'
    click_on 'Save'

    expect(page).to have_css 'tr', text: '/endpoint', count: 1

    response = get '/endpoint'
    expect(response.status).to eq 202
    expect(response.body).to eq 'New UI Body'
  end

  it 'can reset the matcher' do
    visit '/'

    click_on '/endpoint'

    expect(page).to have_field 'Status code', with: 200
    expect(page).to have_field 'Response body', with: "Hi!"
    fill_in 'Status code', with: 202
    fill_in 'Response body', with: 'New UI Body'
    click_on 'Save'

    expect(page).to have_css 'tr', text: '/endpoint', count: 1

    within 'tr', text: '/endpoint' do
      click_on 'Reset'
    end

    expect(page).to have_css 'tr', text: '/endpoint', count: 1

    response = get '/endpoint'
    expect(response.status).to eq 200
    expect(response.body).to eq 'Hi!'
  end

  it 'shows the number of times that a request has been made to that endpoint' do
    get '/endpoint'
    get '/endpoint'
    get '/endpoint'

    visit '/'

    expect(page).to have_css 'tr', text: '3'
  end

  it 'can show requests to the endpoint' do
    get '/endpoint', '', {'HTTP_X_CUSTOM_HEADER' => 'foo bar!'}

    visit '/'

    within 'tr', text: '/endpoint' do
      click_on '1'
    end

    expect(page).to have_content 'Requests to GET /endpoint'
    expect(page).to have_content 'X-CUSTOM-HEADER: foo bar!'
  end

  it 'can modify regexp/body matchers' do
    visit '/'

    within 'tr', text: 'key1' do
      click_on '/matcher'
    end

    expect(page).to have_content 'Response for POST /matcher'
    expect(page).to have_field 'Match body on', with: 'key1', disabled: true
    fill_in 'Response body', with: 'Hola friend'
    click_on 'Save'

    response = post '/matcher', 'key1'
    expect(response.body).to eq 'Hola friend'
  end

  it 'can verify JSON schemas against bodies' do
    visit '/'

    click_on '/endpoint'
    fill_in 'Response schema', with: {"type": "object", "properties": {"a": {"type": "integer"}}}.to_json
    fill_in 'Response body', with: '{"a": "b"}'
    click_on 'Save'
    expect(page).to have_content 'Body does not match expected schema'

    fill_in 'Response body', with: '{"a": 1}'
    click_on 'Save'

    expect(page).to have_css 'tr', text: '/endpoint'
  end
end