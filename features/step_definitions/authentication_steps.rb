Given(/^a valid client id and a valid secret$/) do
  ENV['PERSONA_OAUTH_CLIENT'] = 'primate'
  ENV['PERSONA_OAUTH_SECRET'] = 'bananas'
end

Given(/^an invalid client id and an invalid secret$/) do
  ENV['PERSONA_OAUTH_CLIENT'] = 'complete'
  ENV['PERSONA_OAUTH_SECRET'] = 'rubbish'
end

Given(/^I am authenticated as a superuser client$/) do
  steps 'Given a valid client id and a valid secret'
  steps 'When I attempt to authenticate'
end

# rubocop:disable Metrics/LineLength
Given(/^I am authenticated as a client with the scopes of "([^"]*)"$/) do |scopes|
  @required_scopes = scopes.split(', ')
end

When(/^I attempt to authenticate$/) do
  begin
    @talis = Talis.new(host: 'http://persona')
    @authenticated = true
  rescue Talis::Errors::AuthenticationFailedError
    fail_with 'authentication failed'
  end
end

When(/^I retrieve my scopes$/) do
  steps 'When I attempt to authenticate'
end

When(/^I try to add the scope of "([^"]*)" to my client$/) do |scope|
  @talis.add_scope(scope)
end

Then(/^I should have the scope of "([^"]*)"$/) do |scope|
  expect(@talis.scopes).to include(scope)
end

Then(/^I should have the scopes "([^"]*)"$/) do |scopes|
  scopes.split(', ').each do |scope|
    expect(@talis.scopes).to include(scope)
  end
end

Then(/^I should be authenticated$/) do
  expect(@authenticated).to be_truthy
end

Then(/^I should not be authenticated$/) do
  expect(@authenticated).to be_falsey
end
