# Geo-Feed
___
###GA WDI NY August 2014, Project 1
Geo-Feed is a location based social media aggregator. The user can search for a location by keywords (ie. Paris, Times Square, Brazil, Catskill Mountains) and an editable snapshot of Instagram photos, Twitter Trends and Tweets is displayed. Geo-Feed saves all of a users snapshots in their profile.

Write a Readme that includes:
the project's name and description,
APIs or Gems used and descriptions of each,
instructions for downloading the code and running it on localhost, and
instructions for running the accompanying test suite.
Present your work to the class on the final day of the project, and participate in the class retrospective.
(after) Deploy the application to Heroku (this will be the version of the application that you share with the class).
gist.github.com
### Screen Shots
___
<img width=720px src="/Users/gray/Desktop/Screen Shot 2014-09-10 at 2.12.24 PM.png">
<img width=720px src="/Users/gray/Desktop/Screen Shot 2014-09-10 at 2.18.55 PM.png">

###Technologies
___

- Ruby "2.1.2"
- Sinatra - Routing
- Redis — Cache and for transient data.
- Heroku - Deployment
Plus lots of Ruby Gems, a complete list of which is at /master/Gemfile.

###User Stories Completed
___
- A user should be able to login via Google+
- A user should be immediately prompted with their profile after login
- A user should be able to see a list of the previous Snapshots they have taken in their profile
- A user should be able to click on each list item to view that snapshot
- A snapshot should contain Instagram the latest Instagram photos, Twitter Trends and Tweets specific to the snapshot's location
- A user should be able to create new Snapshots by entering a location keyword
- A user should be able to edit all snapshots and access them in their latest state
- A user's snapshots should persist from session to session