require File.expand_path(File.dirname(__FILE__) + '/common')

describe "communication channel selenium tests" do
  include_context "in-process server selenium tests"

  context "confirm" do
    it "should register the user" do
      Setting.set('terms_required', 'false')
      u1 = user_with_communication_channel(:user_state => 'creation_pending')
      get "/register/#{u1.communication_channel.confirmation_code}"
      set_value f('#pseudonym_password'), "asdfasdf"
      expect_new_page_load {
        f('#registration_confirmation_form').submit
      }
      expect(f('#identity .logout')).to be_present
    end

    it "should require the terms if configured to do so" do
      u1 = user_with_communication_channel(:user_state => 'creation_pending')
      get "/register/#{u1.communication_channel.confirmation_code}"
      expect(f('input[name="user[terms_of_use]"]')).to be_present
      f('#registration_confirmation_form').submit
      wait_for_ajaximations
      assert_error_box 'input[name="user[terms_of_use]"]:visible'
    end

    it "should not require the terms if the user has already accepted them" do
      u1 = user_with_communication_channel(:user_state => 'creation_pending')
      u1.preferences[:accepted_terms] = Time.now.utc
      u1.save
      get "/register/#{u1.communication_channel.confirmation_code}"
      expect(f('input[name="user[terms_of_use]"]')).not_to be_present
    end

    it "should allow the user to edit the pseudonym if its already taken" do
      u1 = user_with_communication_channel(:username => 'asdf@qwerty.com', :user_state => 'creation_pending')
      u1.accept_terms
      u1.save
      # d'oh, now it's taken
      u2 = user_with_pseudonym(:username => 'asdf@qwerty.com', :active_user => true)

      get "/register/#{u1.communication_channel.confirmation_code}"
      # they can set it...
      input = f('#pseudonym_unique_id')
      expect(input).to be_present
      set_value input, "asdf@asdf.com"
      set_value f('#pseudonym_password'), "asdfasdf"
      expect_new_page_load {
        f('#registration_confirmation_form').submit
      }

      expect(f('#identity .logout')).to be_present
    end

    it 'should show the bounce count reset button when a siteadmin is masquerading' do
      u = user_with_pseudonym(active_all: true)
      cc = u.communication_channels.create!(:path => 'test@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active'; cc.bounce_count = 3 }
      site_admin_logged_in
      masquerade_as(u)

      get '/profile/settings'

      expect(f('.reset_bounce_count_link')).to be_present
    end

    it 'should not show the bounce count reset button when an account admin is masquerading' do
      u = user_with_pseudonym(active_all: true)
      cc = u.communication_channels.create!(:path => 'test@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active'; cc.bounce_count = 3 }
      admin_logged_in
      masquerade_as(u)

      get '/profile/settings'

      expect(f('.reset_bounce_count_link')).to be_nil
    end

    it 'should not show the bounce count reset button when the channel is not bouncing' do
      u = user_with_pseudonym(active_all: true)
      cc = u.communication_channels.create!(:path => 'test@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      site_admin_logged_in
      masquerade_as(u)

      get '/profile/settings'

      expect(f('.reset_bounce_count_link')).to be_nil
    end
  end
end
