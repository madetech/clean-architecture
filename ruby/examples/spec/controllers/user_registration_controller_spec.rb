describe UserRegistrationController do
  let(:email) { 'a@a.com' }

  before do
    subject.params = { email: email }
    subject.create
  end

  context 'when using with form helper' do
    let(:html) { '' }

    before do
      html << View.new.form_for(subject.user_instance_var) do |f|
        html << f.email_field(:email)
        html << f.submit
      end
    end

    it 'should work with Rails forms correctly' do
      expect(html).to include(email)
    end
  end

  context 'when email missing' do
    let(:email) { nil }

    it 'should contain Rails errors' do
      expect(subject.user_instance_var.errors.messages).to include(email: ['can\'t be blank'])
    end
  end
end
