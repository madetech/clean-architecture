describe Orders::Gateway::Order do
  context 'when finding order by id' do
    subject { described_class.new.find_order_by_id(1) }

    it { is_expected.to be_a(Orders::Domain::DiscountableOrder) }
    it { is_expected.to have_discount }

    it 'should have correct discount' do
      expect(subject.discount).to eq(10)
    end
  end

  context 'when saving order discount' do
    subject { described_class.new.save_order_discount(1, Orders::Domain::DiscountableOrder.new(10)) }
    it { is_expected.to eq(true) }
  end
end
