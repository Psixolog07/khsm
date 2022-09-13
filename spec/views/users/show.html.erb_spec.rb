require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryGirl.create(:user, name: 'Вадик', balance: 5000, email: '123@mail.ru')}

  before  do
    assign(:user, user)
    assign(:games, [FactoryGirl.build_stubbed(:game, id: 1, created_at: Time.now, current_level: 0)])
    stub_template 'users/_game.html.erb' => 'User game goes here'
  end

  context "user is profile owner" do
    before do
      sign_in user
      render
    end
  
    it 'renders player name' do
      expect(rendered).to match 'Вадик'
    end
    
    it 'renders users/_game.html.erb' do
      expect(rendered).to match 'User game goes here'
    end
  
    it 'renders change password link' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end
  
  context "user is NOT profile owner" do
    let(:user2) {FactoryGirl.create(:user, name: 'Гадик', balance: 2000, email: '456@mail.ru')}

    before do
      sign_in user2
      render
    end

    it 'renders player-owner name' do
      expect(rendered).to match 'Вадик'
    end

    it 'renders users/_game.html.erb' do
      expect(rendered).to match 'User game goes here'
    end

    it 'NOT renders change password link' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
