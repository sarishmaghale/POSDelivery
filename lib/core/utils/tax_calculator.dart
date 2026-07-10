const double kDefaultTaxPercent = 13.0;

class ItemTaxBreakdown {
  final double rateExTax;
  final double rateIncTax;
  final double grossAmount;
  final double grossAmountIncTax;
  final double taxableAmount;
  final double nonTaxableAmount;
  final double taxAmount;
  final double discountExcTax;
  final double discountIncludingTax;
  final double netAmount;

  const ItemTaxBreakdown({
    required this.rateExTax,
    required this.rateIncTax,
    required this.grossAmount,
    required this.grossAmountIncTax,
    required this.taxableAmount,
    required this.nonTaxableAmount,
    required this.taxAmount,
    required this.discountExcTax,
    required this.discountIncludingTax,
    required this.netAmount,
  });
}

ItemTaxBreakdown computeItemTax({
  required double rate,
  required double quantity,
  required double discount,
  required int taxableType,
  double taxPercent = kDefaultTaxPercent,
}) {
  double rateExTax;
  double rateIncTax;
  double grossAmount;
  double grossAmountIncTax;
  double taxableAmount;
  double nonTaxableAmount;
  double taxAmount;
  double discountExcTax;
  double discountIncludingTax;

  if (taxableType == 0) {
    rateExTax = rate;
    rateIncTax = rate * (1 + taxPercent / 100);
    grossAmount = rateExTax * quantity;
    grossAmountIncTax = rateIncTax * quantity;
    taxableAmount = grossAmount;
    nonTaxableAmount = 0;
    taxAmount = (grossAmount - discount) * (taxPercent / 100);
    discountExcTax = discount;
    discountIncludingTax = discount * (1 + taxPercent / 100);
  } else if (taxableType == 1) {
    rateIncTax = rate;
    rateExTax = rate / (1 + taxPercent / 100);
    grossAmountIncTax = rateIncTax * quantity;
    grossAmount = rateExTax * quantity;
    taxableAmount = grossAmount;
    nonTaxableAmount = 0;
    discountIncludingTax = discount;
    discountExcTax = discount / (1 + taxPercent / 100);
    taxAmount = grossAmountIncTax - grossAmount;
  } else {
    rateExTax = rate;
    rateIncTax = rate;
    grossAmount = rateExTax * quantity;
    grossAmountIncTax = grossAmount;
    taxableAmount = 0;
    nonTaxableAmount = grossAmount;
    taxAmount = 0;
    discountIncludingTax = discount;
    discountExcTax = discount;
  }

  final netAmount = grossAmountIncTax - discountIncludingTax;

  return ItemTaxBreakdown(
    rateExTax: rateExTax,
    rateIncTax: rateIncTax,
    grossAmount: grossAmount,
    grossAmountIncTax: grossAmountIncTax,
    taxableAmount: taxableAmount,
    nonTaxableAmount: nonTaxableAmount,
    taxAmount: taxAmount,
    discountExcTax: discountExcTax,
    discountIncludingTax: discountIncludingTax,
    netAmount: netAmount,
  );
}
