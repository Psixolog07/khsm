require 'rails_helper'
# Сразу подключим наш модуль с вспомогательными методами
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'Anon' do
    # Аноним не может смотреть игру
    it 'kicks from #show' do
      # Вызываем экшен
      get :show, id: game_w_questions.id
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    context 'tried to use #create and' do
      before { post :create }
      
      it 'did not get 200 responce' do
        expect(response.status).not_to eq(200)
      end

      it 'got redirected to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'saw flash message' do
        expect(flash[:alert]).to be
      end
    end

    context 'tried to use #answer and' do
      before { put :answer,  id: game_w_questions.id }
      
      it 'did not get 200 responce' do
        expect(response.status).not_to eq(200)
      end

      it 'got redirected to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'saw flash message' do
        expect(flash[:alert]).to be
      end
    end

    context 'tried to use #teke_money and' do
      before { put :answer,  id: game_w_questions.id }
      
      it 'did not get 200 responce' do
        expect(response.status).not_to eq(200)
      end

      it 'got redirected to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'saw flash message' do
        expect(flash[:alert]).to be
      end
    end
  end

  context 'Usual user' do

    # Этот блок будет выполняться перед каждым тестом в группе
    # Логиним юзера с помощью девайзовского метода sign_in
    before(:each) { sign_in user }
  
    it 'creates game' do
      # Создадим пачку вопросов
      generate_questions(15)
  
      # Экшен create у нас отвечает на запрос POST
      post :create
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)
  
      # Проверяем состояние этой игры: она не закончена
      # Юзер должен быть именно тот, которого залогинили
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # Проверяем, есть ли редирект на страницу этой игры
      # И есть ли сообщение об этом
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      # Показываем по GET-запросу
      get :show, id: game_w_questions.id
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)
      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Юзер именно тот, которого залогинили
      expect(game.user).to eq(user)
    
      # Проверяем статус ответа (200 ОК)
      expect(response.status).to eq(200)
      # Проверяем рендерится ли шаблон show (НЕ сам шаблон!)
      expect(response).to render_template('show')
    end

    it 'answers correct' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)
    
      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Уровень больше 0
      expect(game.current_level).to be > 0
    
      # Редирект на страницу игры
      expect(response).to redirect_to(game_path(game))
      # Флеш пустой
      expect(flash.empty?).to be_truthy
    end
    

    it '#show alien game' do
      alien_game = FactoryGirl.create(:game_with_questions)
      get :show, id: alien_game.id
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'takes money' do
      game_w_questions.update_attribute(:current_level, 2)
      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)
      user.reload
      expect(user.balance).to eq(200)
      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    it 'try to create second game' do
      expect(game_w_questions.finished?).to be_falsey
      expect { post :create }.to change(Game, :count).by(0)
      game = assigns(:game)
      expect(game).to be_nil
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    context 'gave wrong answer and' do
      let!(:answer_key) do 
        %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample
      end

      before do
        put :answer, id: game_w_questions.id, letter: answer_key
        @game = assigns(:game)
      end

      it 'game was over' do
        expect(@game.finished?).to be true
      end

      it 'game finishes with status fail' do
        expect(@game.status).to eq(:fail)
      end

      it 'was redirected to his profile' do
        expect(response).to redirect_to(user_path(@game.user))
      end

      it 'got flash message' do
        expect(flash[:alert]).to be
      end
    end

    it 'uses audience help' do
      # Проверяем, что у текущего вопроса нет подсказок
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      # И подсказка не использована
      expect(game_w_questions.audience_help_used).to be_falsey
    
      # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)
    
      # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end
  end  
end
