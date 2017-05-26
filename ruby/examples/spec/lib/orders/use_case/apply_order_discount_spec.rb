describe Orders::UseCase::ApplyOrderDiscount do
  let(:gateway) { double(find_order_by_id: order, save_order_discount: true) }
  subject { described_class.new(gateway: gateway).apply(double(id: 1)) }

  context 'when order has not existing discounts' do
    let(:order) { Orders::Domain::DiscountableOrder.new(0) }
    it { is_expected.to have_discount }
    it { expect(subject.discount).to eq(10) }
  end

  context 'when order has existing discounts' do
    let(:order) { Orders::Domain::DiscountableOrder.new(5) }
    it { is_expected.to have_discount }
    it { expect(subject.discount).to eq(5) }
  end
end
