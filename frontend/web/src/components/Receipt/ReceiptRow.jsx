import "./ReceiptRow.css";

export default function ReceiptRow({ item, onUpdateQty, onRemove, onAssign }) {
    return (
        <div className={`receipt-row ${!item.known ? "unknown" : ""}`}>
            <button
                className="remove-btn"
                onClick={() => onRemove(item.id)}
                title="Remove item"
            >
                ✕
            </button>

            <div className="receipt-row-left">
                <span className="item-name">
                    {item.name}
                    {!item.known && <span className="unknown-badge">?</span>}
                </span>
                <span className="item-class">{item.yolo_class}</span>
            </div>

            <div className="receipt-row-right">
                {item.confidence != null && (
                    <span className="item-confidence">
                        {(item.confidence * 100).toFixed(0)}%
                    </span>
                )}

                {item.known ? (
                    <>
                        <div className="qty-controls">
                            <button
                                className="qty-btn"
                                onClick={() => onUpdateQty(item.id, -1)}
                                disabled={item.quantity <= 1}
                            >
                                −
                            </button>
                            <span className="qty-value">{item.quantity}</span>
                            <button
                                className="qty-btn"
                                onClick={() => onUpdateQty(item.id, 1)}
                            >
                                +
                            </button>
                        </div>
                        <span className="item-price">
                            RM {(item.price * item.quantity).toFixed(2)}
                        </span>
                    </>
                ) : (
                    <button
                        className="assign-btn"
                        onClick={() => onAssign(item.yolo_class)}
                    >
                        Assign
                    </button>
                )}
            </div>
        </div>
    );
}
