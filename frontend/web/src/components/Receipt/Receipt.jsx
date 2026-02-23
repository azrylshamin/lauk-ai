import ReceiptRow from "./ReceiptRow";
import AssignForm from "../AssignForm/AssignForm";
import "./Receipt.css";

export default function Receipt({
    items,
    itemCount,
    total,
    hasUnknown,
    confirming,
    assigningClass,
    onUpdateQty,
    onRemove,
    onStartAssign,
    onAssignSave,
    onAssignCancel,
    onAddItem,
    onConfirm,
}) {
    return (
        <div className="receipt">
            <div className="receipt-header">
                <h2>Order Summary</h2>
                <span className="item-count">{itemCount} items</span>
            </div>

            {items.length === 0 ? (
                <p className="no-results">
                    All items removed. Use "Add Item" to build your order.
                </p>
            ) : (
                <div className="receipt-items">
                    {items.map((item) => (
                        <ReceiptRow
                            key={item.id}
                            item={item}
                            onUpdateQty={onUpdateQty}
                            onRemove={onRemove}
                            onAssign={onStartAssign}
                        />
                    ))}
                </div>
            )}

            {assigningClass && (
                <AssignForm
                    yoloClass={assigningClass}
                    onSave={onAssignSave}
                    onCancel={onAssignCancel}
                />
            )}

            <button className="add-item-btn" onClick={onAddItem}>
                <span className="add-icon">+</span> Add Item
            </button>

            {hasUnknown && (
                <p className="unknown-hint">
                    Items marked with <span className="unknown-badge inline">?</span>{" "}
                    are not in the menu. Click "Assign" to add them.
                </p>
            )}

            <div className="receipt-total">
                <span className="total-label">Total</span>
                <span className="total-price">
                    RM {(Math.round(total * 100) / 100).toFixed(2)}
                </span>
            </div>

            <button
                className="confirm-btn"
                onClick={onConfirm}
                disabled={confirming || items.length === 0 || hasUnknown}
            >
                {confirming ? "Saving..." : "Confirm Order"}
            </button>
        </div>
    );
}
