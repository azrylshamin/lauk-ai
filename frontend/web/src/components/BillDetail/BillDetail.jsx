import "./BillDetail.css";

function formatDateTime(dateStr) {
    return new Date(dateStr).toLocaleString("en-MY", {
        weekday: "short",
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
}

export default function BillDetail({ bill, onClose }) {
    return (
        <div className="bill-detail-overlay" onClick={onClose}>
            <div
                className="bill-detail-sheet"
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header */}
                <div className="bill-detail-header">
                    <div>
                        <h3>Bill #{bill.id}</h3>
                        <span className="bill-detail-time">
                            {formatDateTime(bill.created_at)}
                        </span>
                    </div>
                    <button className="bill-detail-close" onClick={onClose}>
                        ✕
                    </button>
                </div>

                {/* Items */}
                <div className="bill-detail-items">
                    {bill.items &&
                        bill.items.map((item) => (
                            <div key={item.id} className="bill-detail-row">
                                <div className="bill-detail-row-left">
                                    <span className="bill-detail-item-name">
                                        {item.name}
                                    </span>
                                    <span className="bill-detail-item-qty">
                                        × {item.quantity}
                                    </span>
                                </div>
                                <span className="bill-detail-item-price">
                                    RM{" "}
                                    {(
                                        parseFloat(item.price) * item.quantity
                                    ).toFixed(2)}
                                </span>
                            </div>
                        ))}
                </div>

                {/* Tax Breakdown */}
                {bill.subtotal != null && (parseFloat(bill.sst_amount) > 0 || parseFloat(bill.sc_amount) > 0) && (
                    <div className="bill-detail-breakdown">
                        <div className="bill-detail-line">
                            <span>Subtotal</span>
                            <span>RM {parseFloat(bill.subtotal).toFixed(2)}</span>
                        </div>
                        {parseFloat(bill.sst_amount) > 0 && (
                            <div className="bill-detail-line tax-line">
                                <span>SST</span>
                                <span>RM {parseFloat(bill.sst_amount).toFixed(2)}</span>
                            </div>
                        )}
                        {parseFloat(bill.sc_amount) > 0 && (
                            <div className="bill-detail-line tax-line">
                                <span>Service Charge</span>
                                <span>RM {parseFloat(bill.sc_amount).toFixed(2)}</span>
                            </div>
                        )}
                    </div>
                )}

                {/* Total */}
                <div className="bill-detail-total">
                    <span className="bill-detail-total-label">Total</span>
                    <span className="bill-detail-total-value">
                        RM {parseFloat(bill.total).toFixed(2)}
                    </span>
                </div>
            </div>
        </div>
    );
}
