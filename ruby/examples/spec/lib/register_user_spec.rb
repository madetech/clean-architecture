describe RegisterUser do
  subject do
    register_user = described_class.new(gateway: FakeGateway.new)
    register_user.register(RegisterUser::Request.new(email))
  end

  context 'when user created without errors' do
    let(:email) { 'a@a.com' }
    it { expect(subject.values).to include(email: email) }
    it { expect(subject.errors).to be_empty }
  end

  context 'when user has errors' do
    let(:email) { nil }
    it { expect(subject.values).to include(email: email) }
    it { expect(subject.errors).to_not be_empty }
  end
end

describe RegisterUser::Gateway do
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
