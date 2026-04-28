export interface CheckoutPricingInput {
  basketPrice: number;
  estimatedTotal?: number;
  deliveryFee: number;
  discount: number;
}

export interface CheckoutPricingResult {
  subtotalConfirmed: number;
  estimatedUnitDelta: number;
  totalConfirmedWithFee: number;
  totalEstimatedWithFee: number;
  displayTotal: number;
}

export function calculateCheckoutPricing(input: CheckoutPricingInput): CheckoutPricingResult {
  const subtotalConfirmed = Math.max(0, input.basketPrice);
  const estimatedBase = Math.max(subtotalConfirmed, input.estimatedTotal ?? subtotalConfirmed);
  const estimatedUnitDelta = Math.max(0, estimatedBase - subtotalConfirmed);

  const totalConfirmedWithFee = Math.max(0, subtotalConfirmed - input.discount + input.deliveryFee);
  const totalEstimatedWithFee = Math.max(0, estimatedBase - input.discount + input.deliveryFee);

  return {
    subtotalConfirmed,
    estimatedUnitDelta,
    totalConfirmedWithFee,
    totalEstimatedWithFee,
    displayTotal: totalEstimatedWithFee,
  };
}
