Feature: Authentication feature

  Scenario: Valid Authentication
    Given a valid client id and a valid secret
    When I attempt to authenticate
    Then I should be authenticated

  Scenario: Scope Retrieval
    Given I am authenticated as a client with the scopes of "foo, bar"
    When I retrieve my scopes
    Then I should have the scopes "foo, bar"

  Scenario: Scope Addition as a superuser
    Given I am authenticated as a superuser client
    When I try to add the scope of "foo" to my client
    Then I should have the scope of "foo"

  Scenario: Invalid Authentication
    Given an invalid client id and an invalid secret
    When I attempt to authenticate
    Then I should not be authenticated
