require "rails_helper"

RSpec.feature "USER creates a game", type: :feature do
  let!(:user) {FactoryGirl.create(:user, name: "Вадик", balance: 5000, email: "123@mail.ru")}
  let(:user2) {FactoryGirl.create(:user, name: "Гадик", balance: 2000, email: "456@mail.ru")}
  let!(:games) do
    [FactoryGirl.create(:game, user_id: user.id, created_at: Time.now, current_level: 0),
      FactoryGirl.create(:game, user_id: user.id, created_at: Time.parse('2019.09.16, 7:45'), finished_at: Time.parse('2019.09.16, 8:00'), current_level: 15, prize: 1_000_000),
      FactoryGirl.create(:game, user_id: user.id, created_at: Time.parse('2019.09.16, 8:45'), finished_at: Time.parse('2019.09.16, 9:00'), current_level: 1, prize: 200)]
    end 

  before {login_as user2}

  scenario "user view another user profile and" do
    visit "/users/#{user.id}"

    expect(page).not_to match "Сменить имя и пароль"

    expect(page).to have_content "Вадик"

    expect(page).to have_content games[0].id
    expect(page).to have_content games[1].id
    expect(page).to have_content games[2].id

    expect(page).to have_content 'в процессе'
    expect(page).to have_content 'победа'
    expect(page).to have_content 'деньги'

    expect(page).to have_content '0'
    expect(page).to have_content '1'
    expect(page).to have_content '15'
    
    expect(page).to have_content '16 сент., 07:45'
    expect(page).to have_content '16 сент., 08:45'

    expect(page).to have_content '0 ₽'
    expect(page).to have_content '200 ₽'
    expect(page).to have_content '1 000 000 ₽'
  end
end
