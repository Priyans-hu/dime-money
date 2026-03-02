"use client";

export function PhoneMockup() {
  return (
    <div className="relative mx-auto w-[260px] h-[520px]">
      {/* Phone frame */}
      <div className="absolute inset-0 rounded-[36px] border-2 border-white/10 bg-[#1D1B20] shadow-2xl overflow-hidden">
        {/* Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-6 bg-[#0F0D13] rounded-b-2xl" />

        {/* Screen content */}
        <div className="mt-10 px-4 space-y-4">
          {/* Header */}
          <div className="text-center">
            <p className="text-xs text-[#938F99]">Total Balance</p>
            <p className="text-2xl font-bold text-white">$4,250.00</p>
          </div>

          {/* Mini chart bars */}
          <div className="flex items-end justify-center gap-1.5 h-16">
            {[40, 65, 45, 80, 55, 70, 50].map((h, i) => (
              <div
                key={i}
                className="w-5 rounded-t-sm"
                style={{
                  height: `${h}%`,
                  background:
                    i === 3
                      ? "#D0BCFF"
                      : "rgba(103, 80, 164, 0.4)",
                }}
              />
            ))}
          </div>

          {/* Transaction list */}
          <div className="space-y-2.5">
            {[
              { emoji: "🛒", label: "Groceries", amount: "-$45.20", color: "#EF9A9A" },
              { emoji: "☕", label: "Coffee", amount: "-$5.50", color: "#FFCC80" },
              { emoji: "💰", label: "Salary", amount: "+$3,200", color: "#A5D6A7" },
              { emoji: "🎬", label: "Netflix", amount: "-$15.99", color: "#CE93D8" },
            ].map((tx) => (
              <div
                key={tx.label}
                className="flex items-center justify-between bg-white/5 rounded-lg px-3 py-2"
              >
                <div className="flex items-center gap-2">
                  <span className="text-sm">{tx.emoji}</span>
                  <span className="text-xs text-white/80">{tx.label}</span>
                </div>
                <span className="text-xs font-medium" style={{ color: tx.color }}>
                  {tx.amount}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
