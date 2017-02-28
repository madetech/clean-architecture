describe ApplyOrderDiscount do
  let(:gateway) { double(find_order_by_id: order, save_order_discount: true) }
  subject { described_class.new(gateway: gateway).apply(double(id: 1)) }

  context 'when order has not existing discounts' do
    let(:order) { ApplyOrderDiscount::DiscountableOrder.new(0) }
    it { is_expected.to have_discount }
    it { expect(subject.discount).to eq(10) }
  end

  context 'when order has existing discounts' do
    let(:order) { ApplyOrderDiscount::DiscountableOrder.new(5) }
    it { is_expected.to have_discount }
    it { expect(subject.discount).to eq(5) }
  end
end

describe ApplyOrderDiscount::DiscountableOrder do
  context 'when discount > 0' do
    before { subject.discount = 5 }
    it { is_expected.to have_discount }
  end

  context 'when discount is 0' do
    before { subject.discount = 0 }
    it { is_expected.to_not have_discount }
  end
end

describe ApplyOrderDiscount::Gateway do
  context 'when finding order by id' do
    subject { described_class.new.find_order_by_id(1) }

    it { is_expected.to be_a(ApplyOrderDiscount::DiscountableOrder) }
    it { is_expected.to have_discount }

    it 'should have correct discount' do
      expect(subject.discount).to eq(10)
    end
  end

  context 'when saving order discount' do
    subject { described_class.new.save_order_discount(1, ApplyOrderDiscount::DiscountableOrder.new(10)) }
    it { is_expected.to eq(true) }
  end
end
