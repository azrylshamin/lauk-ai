import { useState, useEffect } from "react";
import { Receipt, Wallet, BarChart3, Target } from "lucide-react";
import { fetchBillStats } from "../../services/api";
import "./StatsBar.css";

export default function StatsBar({ refreshKey }) {
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setLoading(true);
        fetchBillStats()
            .then(setStats)
            .catch(() => setStats(null))
            .finally(() => setLoading(false));
    }, [refreshKey]);

    if (loading) {
        return (
            <div className="stats-bar skeleton">
                {[...Array(4)].map((_, i) => (
                    <div key={i} className="stat-card shimmer" />
                ))}
            </div>
        );
    }

    if (!stats) return null;

    const cards = [
        {
            label: "Today's Bills",
            value: stats.billCount,
            Icon: Receipt,
            accent: "var(--primary)",
        },
        {
            label: "Revenue",
            value: `RM ${stats.revenue.toFixed(2)}`,
            Icon: Wallet,
            accent: "var(--success)",
        },
        {
            label: "Average",
            value: `RM ${stats.average.toFixed(2)}`,
            Icon: BarChart3,
            accent: "var(--secondary)",
        },
        {
            label: "Accuracy",
            value: stats.accuracy != null ? `${stats.accuracy}%` : "—",
            Icon: Target,
            accent: "var(--tertiary)",
        },
    ];

    return (
        <div className="stats-bar">
            {cards.map((card) => (
                <div key={card.label} className="stat-card" style={{ "--card-accent": card.accent }}>
                    <span className="stat-icon"><card.Icon size={22} /></span>
                    <span className="stat-value">{card.value}</span>
                    <span className="stat-label">{card.label}</span>
                </div>
            ))}
        </div>
    );
}
