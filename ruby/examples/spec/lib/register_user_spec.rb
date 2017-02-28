describe RegisterUser do
  subject do
    register_user = described_class.new(gateway: FakeGateway.new)
    register_user.register(RegisterUser::Request.new(email))
  end

  context 'when user created without errors' do
    let(:email) { 'a@a.com' }
    it { expect(subject.errors).to be_empty }
  end

  context 'when user has errors' do
    let(:email) { nil }
    it { expect(subject.errors).to_not be_empty }
  end
end

describe RegisterUser::Gateway do
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
