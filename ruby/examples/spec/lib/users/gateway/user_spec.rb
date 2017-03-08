describe Users::Gateway::User do
  context 'when create user' do
    subject do
      described_class.new.create_user(
        email: email,
        name: 'Luke',
        password: 'pass'
      )
    end

    context 'with valid email' do
      let(:email) { 'luke@cool.com' }
      it { is_expected.to be_empty }
    end

    context 'with missing email' do
      let(:email) { nil }
      it { is_expected.to_not be_empty }
    end
  end
end
