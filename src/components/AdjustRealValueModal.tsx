import { useEffect, useMemo, useState } from "react";
import { DollarSign, Save, X } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";

interface OrderRef {
  id: string;
  customer_name: string;
  status: string;
}

interface OrderItemRow {
  id: string;
  order_id: string;
  product_id: string;
  quantity: number;
  sold_by: "unit" | "weight";
  needs_weighing: boolean | null;
  price: number | null;
  price_per_kg: number | null;
  estimated_price: number | null;
  final_price: number | null;
  actual_weight_kg: number | null;
  product_name: string;
}

interface EntryState {
  weightKg: string;
  finalPrice: string;
}

interface Props {
  order: OrderRef | null;
  onClose: () => void;
  onSuccess: () => void;
}

export function AdjustRealValueModal({ order, onClose, onSuccess }: Props) {
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [items, setItems] = useState<OrderItemRow[]>([]);
  const [entries, setEntries] = useState<Record<string, EntryState>>({});

  useEffect(() => {
    if (!order) return;

    const run = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from("order_items")
        .select(`
          id,
          order_id,
          product_id,
          quantity,
          sold_by,
          needs_weighing,
          price,
          price_per_kg,
          estimated_price,
          final_price,
          actual_weight_kg,
          product:products(name)
        `)
        .eq("order_id", order.id)
        .eq("sold_by", "unit")
        .eq("needs_weighing", true);

      if (error) {
        toast.error("Erro ao carregar itens para ajuste");
        setLoading(false);
        return;
      }

      const normalized = (data ?? []).map((row: any) => ({
        id: row.id,
        order_id: row.order_id,
        product_id: row.product_id,
        quantity: row.quantity ?? 0,
        sold_by: row.sold_by ?? "unit",
        needs_weighing: row.needs_weighing,
        price: row.price ?? 0,
        price_per_kg: row.price_per_kg ?? row.price ?? 0,
        estimated_price: row.estimated_price,
        final_price: row.final_price,
        actual_weight_kg: row.actual_weight_kg,
        product_name: row.product?.name ?? "Produto",
      })) as OrderItemRow[];

      const initialEntries: Record<string, EntryState> = {};
      normalized.forEach((item) => {
        initialEntries[item.id] = {
          weightKg: item.actual_weight_kg ? String(item.actual_weight_kg) : "",
          finalPrice: String(item.final_price ?? item.estimated_price ?? item.price ?? 0),
        };
      });

      setItems(normalized);
      setEntries(initialEntries);
      setLoading(false);
    };

    run();
  }, [order]);

  const hasItemsToAdjust = items.length > 0;

  const canSave = useMemo(() => {
    if (!hasItemsToAdjust) return false;
    return items.every((item) => {
      const entry = entries[item.id];
      if (!entry) return false;
      const finalPrice = Number(entry.finalPrice || "0");
      return finalPrice > 0;
    });
  }, [entries, hasItemsToAdjust, items]);

  const handleWeightChange = (item: OrderItemRow, value: string) => {
    const safe = value.replace(/[^0-9.]/g, "");
    const weight = Number(safe || "0");
    const pricePerKg = item.price_per_kg ?? item.price ?? 0;
    const calculatedFinal = weight > 0 && pricePerKg > 0 ? (weight * pricePerKg).toFixed(2) : entries[item.id]?.finalPrice ?? "";

    setEntries((prev) => ({
      ...prev,
      [item.id]: {
        weightKg: safe,
        finalPrice: calculatedFinal,
      },
    }));
  };

  const handleFinalPriceChange = (itemId: string, value: string) => {
    const safe = value.replace(/[^0-9.]/g, "");
    setEntries((prev) => ({
      ...prev,
      [itemId]: {
        ...(prev[itemId] ?? { weightKg: "", finalPrice: "" }),
        finalPrice: safe,
      },
    }));
  };

  const handleSave = async () => {
    if (!order || !canSave) return;
    setSaving(true);

    try {
      const { data: authData } = await supabase.auth.getUser();
      const weighedBy = authData.user?.id ?? null;

      for (const item of items) {
        const entry = entries[item.id];
        if (!entry) continue;

        const finalPrice = Number(entry.finalPrice || "0");
        const enteredWeight = Number(entry.weightKg || "0");
        const pricePerKg = item.price_per_kg ?? item.price ?? 0;
        const actualWeightKg =
          enteredWeight > 0 ? enteredWeight : pricePerKg > 0 ? Number((finalPrice / pricePerKg).toFixed(3)) : null;

        if (!actualWeightKg || actualWeightKg <= 0) {
          throw new Error(`Informe peso ou valor válido para ${item.product_name}`);
        }

        const { error: updateError } = await supabase
          .from("order_items")
          .update({
            actual_weight_kg: actualWeightKg,
            final_price: finalPrice,
            needs_weighing: false,
          })
          .eq("id", item.id);

        if (updateError) throw updateError;

        await (supabase as any).from("weighing_history").insert({
          order_item_id: item.id,
          order_id: item.order_id,
          product_name: item.product_name,
          quantity: item.quantity,
          estimated_weight_kg: null,
          actual_weight_kg: actualWeightKg,
          estimated_price: item.estimated_price,
          final_price: finalPrice,
          price_per_kg: pricePerKg,
          weighed_by: weighedBy,
          notes: "Ajuste de valor real via painel admin",
        });
      }

      // Recalcula total via RPC (fallback manual se função não existir).
      const rpcResult = await (supabase as any).rpc("recalculate_order_total", { p_order_id: order.id });
      if (rpcResult?.error) {
        const { data: orderItems } = await supabase
          .from("order_items")
          .select("quantity, sold_by, price, final_price")
          .eq("order_id", order.id);

        const { data: orderData } = await supabase
          .from("orders")
          .select("delivery_fee, discount")
          .eq("id", order.id)
          .single();

        const itemsSum = (orderItems ?? []).reduce((sum: number, row: any) => {
          if (row.sold_by === "unit") {
            if (typeof row.final_price === "number") return sum + row.final_price;
            return sum + (row.quantity ?? 0) * (row.price ?? 0);
          }
          return sum + (row.final_price ?? row.price ?? 0);
        }, 0);

        const newTotal = Math.max(0, itemsSum + (orderData?.delivery_fee ?? 0) - (orderData?.discount ?? 0));
        await supabase.from("orders").update({ total: newTotal }).eq("id", order.id);
      }

      toast.success("Valor real ajustado com sucesso");
      onSuccess();
      onClose();
    } catch (error: any) {
      console.error(error);
      toast.error(error?.message || "Erro ao ajustar valor real");
    } finally {
      setSaving(false);
    }
  };

  if (!order) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-card w-full max-w-2xl rounded-2xl border border-border shadow-xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-foreground">Ajustar valor real</h3>
            <p className="text-xs text-muted-foreground">
              Pedido #{order.id.split("-")[0]} · {order.customer_name}
            </p>
          </div>
          <button
            onClick={onClose}
            className="h-8 w-8 rounded-lg bg-muted hover:bg-accent flex items-center justify-center"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="p-4 overflow-y-auto flex-1 space-y-3">
          {loading ? (
            <p className="text-sm text-muted-foreground">Carregando itens...</p>
          ) : !hasItemsToAdjust ? (
            <p className="text-sm text-muted-foreground">Sem itens estimados pendentes para ajuste.</p>
          ) : (
            items.map((item) => (
              <div key={item.id} className="rounded-xl border border-border p-3 bg-card space-y-2">
                <p className="font-bold text-foreground">{item.product_name}</p>
                <p className="text-xs text-muted-foreground">
                  {item.quantity} unidade(s) · base R$ {(item.price_per_kg ?? item.price ?? 0).toFixed(2)}/kg
                </p>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    value={entries[item.id]?.weightKg ?? ""}
                    onChange={(e) => handleWeightChange(item, e.target.value)}
                    placeholder="Peso real (kg)"
                    className="h-10 rounded-lg border border-border px-3 text-sm bg-card"
                  />
                  <input
                    value={entries[item.id]?.finalPrice ?? ""}
                    onChange={(e) => handleFinalPriceChange(item.id, e.target.value)}
                    placeholder="Valor final (R$)"
                    className="h-10 rounded-lg border border-border px-3 text-sm bg-card"
                  />
                </div>
              </div>
            ))
          )}
        </div>

        <div className="p-4 border-t border-border bg-muted/40">
          <button
            onClick={handleSave}
            disabled={!canSave || saving}
            className="w-full h-10 rounded-lg bg-primary text-white text-sm font-bold hover:bg-primary/90 disabled:opacity-50 flex items-center justify-center gap-1"
          >
            {saving ? (
              "Salvando..."
            ) : (
              <>
                <Save className="h-3.5 w-3.5" />
                Salvar ajuste
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
