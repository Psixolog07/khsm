source 'https://rubygems.org'

ruby "2.5.8"

gem 'devise-i18n'
gem 'devise', '~> 4.1.1'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'rails', '~> 4.2.10'
gem 'russian'
gem 'twitter-bootstrap-rails'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'rspec-rails', '~> 3.4'
  gem 'shoulda-matchers'
  gem 'sqlite3', '~> 1.3.13'
end

group :test do
  gem 'capybara'
  gem 'launchy'
end

group :production do
  # гем, улучшающий вывод логов на Heroku
  # https://devcenter.heroku.com/articles/getting-started-with-rails4#heroku-gems
  gem 'pg'
  gem 'rails_12factor'
end
