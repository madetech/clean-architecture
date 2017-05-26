describe Orders::Domain::DiscountableOrder do
  context 'when discount > 0' do
    before { subject.discount = 5 }
    it { is_expected.to have_discount }
  end

  context 'when discount is 0' do
    before { subject.discount = 0 }
    it { is_expected.to_not have_discount }
  end
end
