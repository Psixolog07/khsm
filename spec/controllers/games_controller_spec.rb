require "rails_helper"
require "support/my_spec_helper"

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context "Unlogged in User" do
    describe "#show" do
      before { get :show, id: game_w_questions.id }
      
      it "did not get 200 responce" do
        expect(response.status).not_to eq(200)
      end

      it "redirected to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "saw flash message" do
        expect(flash[:alert]).to be
      end
    end

    describe "#create" do
      before { post :create }
      
      it "did not get 200 responce" do
        expect(response.status).not_to eq(200)
      end

      it "redirected to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "saw flash message" do
        expect(flash[:alert]).to be
      end
    end

    describe "#answer" do
      before { put :answer,  id: game_w_questions.id }
      
      it "did not get 200 responce" do
        expect(response.status).not_to eq(200)
      end

      it "redirected to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "saw flash message" do
        expect(flash[:alert]).to be
      end
    end

    describe "#take_money" do
      before { put :answer,  id: game_w_questions.id }
      
      it "did not get 200 responce" do
        expect(response.status).not_to eq(200)
      end

      it "redirected to login" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "saw flash message" do
        expect(flash[:alert]).to be
      end
    end
  end

  context "Logged in User" do
    before { sign_in user }
    let!(:allowed_keys) { %w[a b c d] }
    let(:game) { assigns(:game) }
  
    describe "#create" do
      context "try to create game" do
        before do
          generate_questions(15)
          post :create
        end

        let!(:game) { assigns(:game) }

        it "game does not end" do
          expect(game.finished?).to be false
        end

        it "current user is equal to logged in one" do
          expect(game.user).to eq(user)
        end 

        it "redirected to game" do
          expect(response).to redirect_to(game_path(game))
        end

        it "saw flash message" do
          expect(flash[:notice]).to be
        end
      end

      context "try to create two games at ones" do
        before do
          game_w_questions
          post :create
        end

        let!(:game) { assigns(:game) }

        it "first game does not end" do
          expect(game_w_questions.finished?).to be false
        end

        it "amount of games did not change" do
          expect { post :create }.to change(Game, :count).by(0)
        end

        it "second game was not created" do
          expect(game).to be nil
        end

        it "redirected to first game" do
          expect(response).to redirect_to(game_path(game_w_questions))
        end

        it "saw flash message" do
          expect(flash[:alert]).to be
        end
      end
    end

    describe "#show" do
      context "user's game" do
        before { get :show, id: game_w_questions.id }

        it "game does not end" do
          expect(game.finished?).to be false
        end

        it "current user is equal to logged in one" do
          expect(game.user).to eq(user)
        end

        it "get 200 responce" do
          expect(response.status).to eq(200)
        end

        it "check render template" do
          expect(response).to render_template("show")
        end
      end

      context "alien game" do
        let(:alien_game) { FactoryGirl.create(:game_with_questions) }
        before { get :show, id: alien_game.id }

        it "did not get 200 responce" do
          expect(response.status).not_to eq(200)
        end

        it "redirected to root" do
          expect(response).to redirect_to(root_path)
        end

        it "saw flash message" do
          expect(flash[:alert]).to be
        end
      end
    end

    describe "#answer" do
      context "answers correct" do
        let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }
        before { put :answer, id: game_w_questions.id, letter: answer_key }

        it "game does not end" do
          expect(game.finished?).to be false
        end

        it "current level is moved" do
          expect(game.current_level).to be > 0
        end

        it "redirected to game" do
          expect(response).to redirect_to(game_path(game))
        end

        it "no flash message" do
          expect(flash.empty?).to be true
        end
      end

      context "answers incorrect" do
        let!(:answer_key) { allowed_keys.grep_v(game_w_questions.current_game_question.correct_answer_key).sample }
        before { put :answer, id: game_w_questions.id, letter: answer_key }
  
        it "game end" do
          expect(game.finished?).to be true
        end
  
        it "game finishes with status fail" do
          expect(game.status).to eq(:fail)
        end
  
        it "redirect to user" do
          expect(response).to redirect_to(user_path(game.user))
        end
  
        it "got flash message" do
          expect(flash[:alert]).to be
        end
      end
    end

    describe "#take_money" do
      before do
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
        user.reload
      end

      it "game end" do
        expect(game.finished?).to be true
      end

      it "game prize is right" do
        expect(game.prize).to eq(200)
      end

      it "user get prize" do
        expect(user.balance).to eq(200)
      end

      it "redirect to user" do
        expect(response).to redirect_to(user_path(user))
      end

      it "got flash message" do
        expect(flash[:warning]).to be
      end
    end

    describe "#help" do
      context "audience_help hint" do
        context "before use" do
          it "current question do not have this hint" do
            expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
          end

          it "hint was not used before" do
            expect(game_w_questions.audience_help_used).to be false
          end
        end

        context "after use" do
          before { put :help, id: game_w_questions.id, help_type: :audience_help }
          let!(:hash) { game.current_game_question.help_hash[:audience_help] }
        
          it "game does not end" do
            expect(game.finished?).to be false
          end

          it "hint was used" do
            expect(game.audience_help_used).to be true
          end

          it "hint hash exist" do
            expect(hash).to be
          end

          it "hash contain allowed keys" do
            expect(allowed_keys - hash.keys).to be_empty
          end

          it "redirects to game" do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end

      context "fifty_fifty hint" do
        context "before use" do
          it "current question do not have this hint" do
            expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
          end

          it "hint was not used before" do
            expect(game_w_questions.fifty_fifty_used).to be false
          end
        end

        context "after use" do
          before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }
          let!(:hash) { game.current_game_question.help_hash[:fifty_fifty] }

          it "game does not end" do
            expect(game.finished?).to be false
          end

          it "hint was used" do
            expect(game.fifty_fifty_used).to be true
          end

          it "hint hash exist" do
            expect(hash).to be
          end

          it "hash have allowed keys" do
            expect(hash - allowed_keys).to be_empty
          end

          it "hint have only 2 keys" do
            expect(hash.size).to eq 2
          end

          it "hint have correct key" do
            expect(hash).to  include(game_w_questions.current_game_question.correct_answer_key)
          end

          it "redirects to game" do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end
    end
  end  
end
