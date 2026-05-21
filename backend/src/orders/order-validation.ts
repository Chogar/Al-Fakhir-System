export type OrderPayload = {
  serviceType: string;
  diningTableId?: string | null;
  items: Array<{ productId: string; quantity: number }>;
};

export function validateOrderPayload(payload: OrderPayload): string | null {
  if (!payload.items?.some((line) => line.quantity > 0)) {
    return 'Au moins un article est requis';
  }
  return null;
}
