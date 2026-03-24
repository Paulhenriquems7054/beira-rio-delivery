import type { BasketProduct } from "@/hooks/useActiveBasket";

// Emojis de vegetais/frutas por nome (fallback visual)
const EMOJI_MAP: Record<string, string> = {
  banana: "🍌",
  tomate: "🍅",
  alface: "🥬",
  batata: "🥔",
  cebola: "🧅",
  maçã: "🍎",
  maca: "🍎",
  laranja: "🍊",
  uva: "🍇",
  abacaxi: "🍍",
  cenoura: "🥕",
  beterraba: "🪔",
  limão: "🍋",
  limao: "🍋",
  melão: "🍈",
  melao: "🍈",
  morango: "🍓",
};

function getProductEmoji(name: string): string {
  const lower = name.toLowerCase();
  for (const key of Object.keys(EMOJI_MAP)) {
    if (lower.includes(key)) return EMOJI_MAP[key];
  }
  return "🥦";
}

interface Props {
  product: BasketProduct;
  cartQty?: number;
  onAdd?: () => void;
  onRemove?: () => void;
}

export function ProductCard({ product, cartQty = 0, onAdd, onRemove }: Props) {
  const emoji = getProductEmoji(product.name);

  return (
    <div className="flex items-center gap-3 rounded-2xl bg-white p-3 shadow-card border border-border/60 transition-transform">
      {/* Avatar com emoji ou imagem */}
      <div className="flex-shrink-0 h-14 w-14 rounded-xl gradient-card flex items-center justify-center overflow-hidden">
        {product.image_url ? (
          <img
            src={product.image_url}
            alt={product.name}
            className="h-full w-full object-cover"
            loading="lazy"
          />
        ) : (
          <span className="text-2xl" role="img" aria-label={product.name}>
            {emoji}
          </span>
        )}
      </div>

      {/* Infos */}
      <div className="flex-1 min-w-0">
        <p className="font-bold text-foreground truncate">{product.name}</p>
        <p className="text-sm text-muted-foreground mt-0.5">
          <span className="text-primary font-bold">
            R$ {product.price.toFixed(2).replace(".", ",")}
          </span>
          <span className="text-xs text-muted-foreground ml-1">
            / {product.unit === "kg" ? "kg" : "un"}
          </span>
        </p>
      </div>

      {/* Controles do Carrinho */}
      {onAdd && onRemove && (
        <div className="flex-shrink-0">
          {cartQty > 0 ? (
            <div className="flex items-center gap-3 bg-accent rounded-full p-1 border border-primary/20">
              <button 
                onClick={onRemove}
                className="h-7 w-7 rounded-full bg-white text-primary font-bold flex items-center justify-center shadow-sm hover:bg-slate-50 transition-colors"
                aria-label="Remover um"
              >
                -
              </button>
              <span className="text-sm font-extrabold text-primary w-3 text-center">{cartQty}</span>
              <button 
                onClick={onAdd}
                className="h-7 w-7 rounded-full bg-primary text-white font-bold flex items-center justify-center shadow-sm hover:bg-primary/90 transition-colors"
                aria-label="Adicionar mais"
              >
                +
              </button>
            </div>
          ) : (
            <button 
              onClick={onAdd}
              className="h-9 px-4 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200 text-sm font-extrabold hover:bg-emerald-100 transition-colors flex items-center gap-1.5"
            >
              Adicionar
            </button>
          )}
        </div>
      )}
    </div>
  );
}
