import ReceiptRow from "./ReceiptRow";
import AssignForm from "../AssignForm/AssignForm";
import "./Receipt.css";

export default function Receipt({
    items,
    itemCount,
    total,
    subtotal,
    sstAmount,
    scAmount,
    grandTotal,
    sstRate,
    scRate,
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
    const hasTax = sstAmount > 0 || scAmount > 0;
    const displayTotal = hasTax ? grandTotal : total;
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
                {hasTax && (
                    <>
                        <div className="receipt-line">
                            <span>Subtotal</span>
                            <span>RM {(Math.round(subtotal * 100) / 100).toFixed(2)}</span>
                        </div>
                        {sstAmount > 0 && (
                            <div className="receipt-line tax-line">
                                <span>SST ({sstRate}%)</span>
                                <span>RM {sstAmount.toFixed(2)}</span>
                            </div>
                        )}
                        {scAmount > 0 && (
                            <div className="receipt-line tax-line">
                                <span>Service Charge ({scRate}%)</span>
                                <span>RM {scAmount.toFixed(2)}</span>
                            </div>
                        )}
                    </>
                )}
                <div className="receipt-total-row">
                    <span className="total-label">Total</span>
                    <span className="total-price">
                        RM {(Math.round(displayTotal * 100) / 100).toFixed(2)}
                    </span>
                </div>
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
