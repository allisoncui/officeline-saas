# OfficeLine: Where Questions Meet Answers

## About the Project

Officeline is a SaaS application that centralizes office hours for students and TAs to effectively browse and give/receive academic help. Features include a virtual queue, real-time updates, push notifications, and a dashboard to submit questions and analyze topics.

## Team Members
- Allison Cui (ac5187)
- Ariel Thongkham (at3731)
- Justin Francisco Rios (jfr2153)
- Raul Hinojos (rh3128)

## Setup and Installation
1. Clone the repository
   ```
   git clone https://github.com/allisoncui/officeline-saas.git
   ```
2. Install dependencies
   ```
   gem install bundler
   bundle install
   ```
3. Create and set up the database
   ```
   bundle exec rails db:create      # create the database
   bundle exec rails db:migrate     # run database migrations to create tables
   ```

## How to Run
Run `bundle exec rails server -b 0.0.0.0` in root directory to start the web server.

To run tests, use the following commands:
* RSpec (unit & integration tests): `bundle exec rspec`
* Cucumber (acceptance & feature tests): `bundle exec cucumber` 

## Heroku Link
https://aqueous-forest-10095-39cac18cf0b2.herokuapp.com/
