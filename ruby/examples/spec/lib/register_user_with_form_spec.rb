describe RegisterUserWithForm do
  let(:email) { 'a@a.com' }

  subject do
    register_user = described_class.new(gateway: FakeGateway.new)
    register_user.register(RegisterUser::Request.new(email))
  end

  context 'when user created without errors' do
    it { expect(subject.form.email).to eq(email) }
    it { expect(subject.form.errors).to be_empty }
  end

  context 'when user has errors' do
    let(:email) { nil }
    it { expect(subject.form.email).to eq(email) }
    it { expect(subject.form.errors).to_not be_empty }
  end

  context 'when using form object with Rails' do
    context 'and using with form helper' do
      let(:html) { '' }

      before do
        html << View.new.form_for(subject.form) do |f|
          html << f.email_field(:email)
          html << f.submit
        end
      end

      it 'should work with Rails forms correctly' do
        expect(html).to include('a@a.com')
      end
    end

    context 'and email missing' do
      let(:email) { nil }

      it 'should contain Rails errors' do
        expect(subject.form.errors.messages).to include(email: ['can\'t be blank'])
      end
    end
  end
end

describe RegisterUserWithForm::Gateway do
  context 'when create user' do
    subject { described_class.new.create_user(email: 'luke@cool.com') }

    context 'and no errors' do
      before { allow(Spree::User).to receive(:create) { double(errors: []) } }
      it { is_expected.to be_empty }
    end

    context 'and errors' do
      before { allow(Spree::User).to receive(:create) { double(errors: [:cool]) } }
      it { is_expected.to include(:cool) }
    end
  end
end
