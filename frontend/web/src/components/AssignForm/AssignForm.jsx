import { useState } from "react";
import "./AssignForm.css";

export default function AssignForm({ yoloClass, onSave, onCancel }) {
    const [name, setName] = useState("");
    const [price, setPrice] = useState("");

    const handleSave = () => {
        if (!name.trim() || !price) return;
        onSave(yoloClass, name.trim(), parseFloat(price));
    };

    return (
        <div className="assign-form">
            <p className="assign-title">
                Assign "<strong>{yoloClass}</strong>" to a menu item
            </p>
            <div className="assign-fields">
                <input
                    type="text"
                    placeholder="Item name (e.g. Ayam)"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                />
                <input
                    type="number"
                    step="0.10"
                    min="0"
                    placeholder="Price (RM)"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                />
            </div>
            <div className="assign-actions">
                <button
                    className="assign-save"
                    onClick={handleSave}
                    disabled={!name.trim() || !price}
                >
                    Save
                </button>
                <button className="assign-cancel" onClick={onCancel}>
                    Cancel
                </button>
            </div>
        </div>
    );
}
