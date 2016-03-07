Given(/^a valid client id and a valid secret$/) do
  ENV['PERSONA_OAUTH_CLIENT'] ||= 'primate'
  ENV['PERSONA_OAUTH_SECRET'] ||= 'bananas'
end

When(/^I attempt to authenticate$/) do
  begin
    @talis = Talis.new(:host => "http://persona")
  rescue Talis::Errors::AuthenticationFailedError
  end
end

Then(/^I should be authenticated$/) do
  expect(@talis.authenticated?).to be_truthy
end
