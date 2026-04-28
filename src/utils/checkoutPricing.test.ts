import { describe, expect, it } from "vitest";
import { calculateCheckoutPricing } from "@/utils/checkoutPricing";

describe("checkout pricing regression", () => {
  it("calcula cenário de item por peso", () => {
    const result = calculateCheckoutPricing({
      basketPrice: 42.5,
      estimatedTotal: 42.5,
      deliveryFee: 0,
      discount: 0,
    });

    expect(result.totalConfirmedWithFee).toBe(42.5);
    expect(result.estimatedUnitDelta).toBe(0);
  });

  it("calcula cenário de item por unidade com preço fixo", () => {
    const result = calculateCheckoutPricing({
      basketPrice: 19.6,
      estimatedTotal: 19.6,
      deliveryFee: 0,
      discount: 0,
    });

    expect(result.totalConfirmedWithFee).toBe(19.6);
    expect(result.totalEstimatedWithFee).toBe(19.6);
  });

  it("calcula cenário de item por unidade com estimativa", () => {
    const result = calculateCheckoutPricing({
      basketPrice: 15,
      estimatedTotal: 23,
      deliveryFee: 0,
      discount: 0,
    });

    expect(result.estimatedUnitDelta).toBe(8);
    expect(result.displayTotal).toBe(23);
  });

  it("aplica cupom + frete + desconto", () => {
    const result = calculateCheckoutPricing({
      basketPrice: 100,
      estimatedTotal: 120,
      deliveryFee: 8,
      discount: 15,
    });

    expect(result.totalConfirmedWithFee).toBe(93);
    expect(result.totalEstimatedWithFee).toBe(113);
  });
});
