import { Moon, Sun } from "lucide-react";
import { useTheme } from "@/hooks/useTheme";

interface ThemeToggleProps {
  variant?: 'default' | 'compact';
  className?: string;
}

export function ThemeToggle({ variant = 'default', className = '' }: ThemeToggleProps) {
  const { theme, toggleTheme } = useTheme();

  if (variant === 'compact') {
    return (
      <button
        onClick={toggleTheme}
        className={`h-8 w-8 rounded-full bg-white/10 dark:bg-slate-800/50 flex items-center justify-center text-white dark:text-slate-200 hover:bg-white/20 dark:hover:bg-slate-700/50 transition-colors ${className}`}
        title={theme === 'light' ? 'Ativar modo escuro' : 'Ativar modo claro'}
      >
        {theme === 'light' ? (
          <Moon className="h-4 w-4" />
        ) : (
          <Sun className="h-4 w-4" />
        )}
      </button>
    );
  }

  return (
    <button
      onClick={toggleTheme}
      className={`relative inline-flex h-10 w-20 items-center rounded-full transition-colors ${
        theme === 'light' 
          ? 'bg-slate-200 dark:bg-slate-700' 
          : 'bg-slate-700 dark:bg-slate-600'
      } ${className}`}
      title={theme === 'light' ? 'Ativar modo escuro' : 'Ativar modo claro'}
    >
      <span
        className={`inline-flex h-8 w-8 transform items-center justify-center rounded-full bg-white dark:bg-slate-800 shadow-md transition-transform ${
          theme === 'dark' ? 'translate-x-11' : 'translate-x-1'
        }`}
      >
        {theme === 'light' ? (
          <Sun className="h-4 w-4 text-amber-500" />
        ) : (
          <Moon className="h-4 w-4 text-blue-400" />
        )}
      </span>
    </button>
  );
}
