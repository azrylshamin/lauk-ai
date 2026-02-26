import { useState, useEffect, useMemo } from "react";
import { ClipboardList } from "lucide-react";
import { fetchBills, fetchBill } from "../../services/api";
import BillDetail from "../BillDetail/BillDetail";
import "./HistoryTab.css";

function formatDate(dateStr) {
    const d = new Date(dateStr);
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);

    const isToday = d.toDateString() === today.toDateString();
    const isYesterday = d.toDateString() === yesterday.toDateString();

    if (isToday) return "Today";
    if (isYesterday) return "Yesterday";

    return d.toLocaleDateString("en-MY", {
        weekday: "short",
        day: "numeric",
        month: "short",
        year: "numeric",
    });
}

function formatTime(dateStr) {
    return new Date(dateStr).toLocaleTimeString("en-MY", {
        hour: "2-digit",
        minute: "2-digit",
    });
}

export default function HistoryTab() {
    const [bills, setBills] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Bill detail state
    const [selectedBill, setSelectedBill] = useState(null);
    const [detailLoading, setDetailLoading] = useState(false);

    useEffect(() => {
        setLoading(true);
        fetchBills()
            .then(setBills)
            .catch((err) => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    const grouped = useMemo(() => {
        const groups = {};
        for (const bill of bills) {
            const key = new Date(bill.created_at).toDateString();
            if (!groups[key]) groups[key] = [];
            groups[key].push(bill);
        }
        return Object.entries(groups);
    }, [bills]);

    const handleBillTap = async (id) => {
        setDetailLoading(true);
        try {
            const bill = await fetchBill(id);
            setSelectedBill(bill);
        } catch (err) {
            setError(err.message);
        } finally {
            setDetailLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="history-loading">
                {[...Array(4)].map((_, i) => (
                    <div key={i} className="history-skeleton shimmer" />
                ))}
            </div>
        );
    }

    if (error) {
        return <div className="error-box">{error}</div>;
    }

    if (bills.length === 0) {
        return (
            <div className="history-empty">
                <span className="history-empty-icon"><ClipboardList size={48} /></span>
                <p>No transactions yet</p>
                <span className="history-empty-sub">
                    Bills you confirm will appear here
                </span>
            </div>
        );
    }

    return (
        <>
            <div className="history-list">
                {grouped.map(([dateKey, dayBills]) => (
                    <div key={dateKey} className="history-group">
                        <div className="history-date">{formatDate(dayBills[0].created_at)}</div>
                        {dayBills.map((bill) => (
                            <button
                                key={bill.id}
                                className="history-row"
                                onClick={() => handleBillTap(bill.id)}
                            >
                                <div className="history-row-left">
                                    <span className="history-row-id">#{bill.id}</span>
                                    <span className="history-row-meta">
                                        {bill.item_count} item{bill.item_count !== 1 ? "s" : ""} ·{" "}
                                        {formatTime(bill.created_at)}
                                    </span>
                                </div>
                                <span className="history-row-total">
                                    RM {parseFloat(bill.total).toFixed(2)}
                                </span>
                            </button>
                        ))}
                    </div>
                ))}
            </div>

            {detailLoading && (
                <div className="bill-detail-overlay">
                    <div className="bill-detail-sheet">
                        <div className="bill-detail-loader">Loading…</div>
                    </div>
                </div>
            )}

            {selectedBill && !detailLoading && (
                <BillDetail
                    bill={selectedBill}
                    onClose={() => setSelectedBill(null)}
                />
            )}
        </>
    );
}
