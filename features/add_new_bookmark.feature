Feature: Adding bookmarks
    Scenario: Adding bookmarks as default user
        Given database is reset
        Given I am on the homepage
        When I follow "Login" within "header"
        When I fill in "user-email" with "user" within "section"
        When I fill in "user-password" with "user" within "section"
        When I press "submit-login" within "section"
        Then I should be on the homepage
        When I follow "Create Bookmark" within "header"
        When I fill in "bookmark-title" with "BBC" within "main"
        When I fill in "bookmark-link" with "bbc.co.uk" within "main"
        When I fill in "bookmark-description" with "Link to the BBC." within "main"
        When I click "#create-bookmark" within "main"
        Then I should see "Bookmark added" within "main"
        When I follow "Go back" within "main"
        Then I should see "BBC" within "main"
        When I follow "BBC" within "main"
        Then I should see "BBC" within ".bookmark-title"
        Then I should see "Link to the BBC." within ".bookmark-description"
        Then I should see "by Testing User" within ".detailed-info"
        Then I should see "Rating: 0/5 (0)" within ".rating"
    
    Scenario: Try adding the same exact bookmark again
        Given I am on the homepage
        When I follow "Login" within "header"
        When I fill in "user-email" with "user" within "section"
        When I fill in "user-password" with "user" within "section"
        When I press "submit-login" within "section"
        Then I should be on the homepage
        When I follow "Create Bookmark" within "header"
        When I fill in "bookmark-title" with "BBC" within "main"
        When I fill in "bookmark-link" with "bbc.co.uk" within "main"
        When I fill in "bookmark-description" with "Link to the BBC." within "main"
        When I click "#create-bookmark" within "main"
        Then I should see "Bookmark added" within "main"
        When I follow "Go back" within "main"
        Then I should see "BBC" within "main"
        When I follow "BBC" within "main"
        Then I should see "BBC" within ".bookmark-title"
        Then I should see "Link to the BBC." within ".bookmark-description"
        Then I should see "by Testing User" within ".detailed-info"
        Then I should see "Rating: 0/5 (0)" within ".rating"

    Scenario: Add the same bookmark as an Admin
        Given I am on the homepage
        When I follow "Login" within "header"
        When I fill in "user-email" with "admin" within "section"
        When I fill in "user-password" with "admin" within "section"
        When I press "submit-login" within "section"
        Then I should be on the homepage
        When I follow "Create Bookmark" within "header"
        When I fill in "bookmark-title" with "BBC" within "main"
        When I fill in "bookmark-link" with "bbc.co.uk" within "main"
        When I fill in "bookmark-description" with "Link to the BBC." within "main"
        When I click "#create-bookmark" within "main"
        Then I should see "Bookmark added" within "main"
        When I follow "Go back" within "main"
        Then I should see "BBC" within "main"
        When I follow "BBC" within "main"
        Then I should see "BBC" within ".bookmark-title"
        Then I should see "Link to the BBC." within ".bookmark-description"
        Then I should see "by Testing User" within ".detailed-info"
        Then I should see "Rating: 0/5 (0)" within ".rating"

    Scenario: Try to add bookmark as an unverified user.
        Given I am on the homepage
        When I follow "Login" within "header"
        When I fill in "user-email" with "role1" within "section"
        When I fill in "user-password" with "role1" within "section"
        When I press "submit-login" within "section"
        Then I should be on the homepage
        When I follow "Create Bookmark" within "header"
        Then I should see "This option is unavailable, because your account hasn't been verified. Please wait for your manager to verify your account."
