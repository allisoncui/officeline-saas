Feature: user authentication
  As a user
  So that I can access the application
  I want to sign up, sign in, and sign out

  Scenario: sign up as a student
    Given I am on the office hours home page
    When I follow "Sign up"
    And I fill in "University ID (UNI)" with "student123"
    And I fill in "Role" with "Student"
    And I fill in "Password" with "password123"
    And I fill in "Password confirmation" with "password123"
    And I press "Sign up"
    Then I should be on the office hours home page
    And I should see "student123"
    And I should see "STUDENT"

  Scenario: sign up as a TA
    Given I am on the office hours home page
    When I follow "Sign up"
    And I fill in "University ID (UNI)" with "ta456"
    And I fill in "Role" with "TA"
    And I fill in "Course Name" with "Engineering SaaS"
    And I fill in "Password" with "password123"
    And I fill in "Password confirmation" with "password123"
    And I press "Sign up"
    Then I should be on the office hours home page
    And I should see "ta456"
    And I should see "TA"

  Scenario: sign in with valid credentials
    Given a student user exists with UNI "student789" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student789"
    And I fill in "Password" with "password123"
    And I press "Log in"
    Then I should be on the office hours home page
    And I should see "student789"
    And I should see "STUDENT"

  Scenario: sign in with invalid credentials
    Given a student user exists with UNI "student789" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student789"
    And I fill in "Password" with "wrongpassword"
    And I press "Log in"
    Then I should see "Invalid UNI or password"

  Scenario: sign out
    Given a student user exists with UNI "student999" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student999"
    And I fill in "Password" with "password123"
    And I press "Log in"
    Then I should be on the office hours home page
    When I press "Log out"
    Then I should be on the sign in page
    And I should see "Sign in"
    And I should see "Sign up"
    And I should not see "student999"

