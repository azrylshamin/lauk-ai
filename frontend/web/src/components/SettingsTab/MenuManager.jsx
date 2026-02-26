import { useState, useEffect } from "react";
import {
    fetchMenuItems,
    assignMenuItem,
    updateMenuItem,
    deleteMenuItem,
} from "../../services/api";
import { Pencil, Trash2, Plus, Check, X, ChevronDown, ChevronUp } from "lucide-react";

export default function MenuManager() {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [editingId, setEditingId] = useState(null);
    const [editFields, setEditFields] = useState({ name: "", price: "" });
    const [showAddForm, setShowAddForm] = useState(false);
    const [addFields, setAddFields] = useState({ yolo_class: "", name: "", price: "" });
    const [saving, setSaving] = useState(false);
    const [confirmDeleteId, setConfirmDeleteId] = useState(null);

    const loadItems = async () => {
        try {
            setLoading(true);
            const data = await fetchMenuItems();
            setItems(data);
            setError(null);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadItems(); }, []);

    // ── Toggle active ───────────────────────────────────────────
    const handleToggle = async (item) => {
        try {
            const updated = await updateMenuItem(item.id, { active: !item.active });
            setItems((prev) => prev.map((i) => (i.id === item.id ? updated : i)));
        } catch (err) {
            setError(err.message);
        }
    };

    // ── Inline edit ─────────────────────────────────────────────
    const startEdit = (item) => {
        setEditingId(item.id);
        setEditFields({ name: item.name, price: item.price });
    };

    const cancelEdit = () => {
        setEditingId(null);
        setEditFields({ name: "", price: "" });
    };

    const saveEdit = async (id) => {
        setSaving(true);
        try {
            const updated = await updateMenuItem(id, {
                name: editFields.name,
                price: parseFloat(editFields.price),
            });
            setItems((prev) => prev.map((i) => (i.id === id ? updated : i)));
            setEditingId(null);
        } catch (err) {
            setError(err.message);
        } finally {
            setSaving(false);
        }
    };

    // ── Delete ──────────────────────────────────────────────────
    const handleDelete = async (id) => {
        try {
            await deleteMenuItem(id);
            setItems((prev) => prev.filter((i) => i.id !== id));
            setConfirmDeleteId(null);
        } catch (err) {
            setError(err.message);
        }
    };

    // ── Add new ─────────────────────────────────────────────────
    const handleAdd = async () => {
        if (!addFields.yolo_class || !addFields.name || !addFields.price) return;
        setSaving(true);
        try {
            const created = await assignMenuItem(
                addFields.yolo_class,
                addFields.name,
                parseFloat(addFields.price)
            );
            setItems((prev) => [...prev, created]);
            setAddFields({ yolo_class: "", name: "", price: "" });
            setShowAddForm(false);
        } catch (err) {
            setError(err.message);
        } finally {
            setSaving(false);
        }
    };

    if (loading) return <div className="settings-loading">Loading menu items…</div>;

    return (
        <div className="settings-section">
            <div className="settings-section-header" onClick={() => { }}>
                <h3>Menu Items</h3>
                <button
                    className="settings-add-btn"
                    onClick={(e) => { e.stopPropagation(); setShowAddForm(!showAddForm); }}
                >
                    {showAddForm ? <X size={14} /> : <Plus size={14} />}
                    {showAddForm ? "Cancel" : "Add Item"}
                </button>
            </div>

            {error && <div className="settings-error">{error}</div>}

            {/* Add new item form */}
            {showAddForm && (
                <div className="settings-add-form">
                    <input
                        type="text"
                        placeholder="YOLO Class (e.g. Chicken)"
                        value={addFields.yolo_class}
                        onChange={(e) => setAddFields({ ...addFields, yolo_class: e.target.value })}
                    />
                    <input
                        type="text"
                        placeholder="Display Name"
                        value={addFields.name}
                        onChange={(e) => setAddFields({ ...addFields, name: e.target.value })}
                    />
                    <input
                        type="number"
                        placeholder="Price"
                        step="0.10"
                        value={addFields.price}
                        onChange={(e) => setAddFields({ ...addFields, price: e.target.value })}
                    />
                    <button className="settings-save-btn" onClick={handleAdd} disabled={saving}>
                        {saving ? "Saving…" : "Add Item"}
                    </button>
                </div>
            )}

            {/* Menu items list */}
            <div className="settings-list">
                {items.length === 0 && <p className="settings-empty">No menu items yet.</p>}
                {items.map((item) => (
                    <div
                        key={item.id}
                        className={`settings-card ${!item.active ? "inactive" : ""}`}
                    >
                        {editingId === item.id ? (
                            <div className="settings-card-edit">
                                <input
                                    type="text"
                                    value={editFields.name}
                                    onChange={(e) => setEditFields({ ...editFields, name: e.target.value })}
                                />
                                <input
                                    type="number"
                                    step="0.10"
                                    value={editFields.price}
                                    onChange={(e) => setEditFields({ ...editFields, price: e.target.value })}
                                />
                                <div className="settings-card-actions">
                                    <button className="icon-btn save" onClick={() => saveEdit(item.id)} disabled={saving}>
                                        <Check size={14} />
                                    </button>
                                    <button className="icon-btn cancel" onClick={cancelEdit}>
                                        <X size={14} />
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <>
                                <div className="settings-card-info">
                                    <span className="card-name">{item.name}</span>
                                    <span className="card-class">{item.yolo_class}</span>
                                    <span className="card-price">RM {parseFloat(item.price).toFixed(2)}</span>
                                </div>
                                <div className="settings-card-actions">
                                    <label className="toggle-switch">
                                        <input
                                            type="checkbox"
                                            checked={item.active !== false}
                                            onChange={() => handleToggle(item)}
                                        />
                                        <span className="toggle-slider" />
                                    </label>
                                    <button className="icon-btn edit" onClick={() => startEdit(item)}>
                                        <Pencil size={14} />
                                    </button>
                                    {confirmDeleteId === item.id ? (
                                        <>
                                            <button className="icon-btn delete confirm" onClick={() => handleDelete(item.id)}>
                                                <Check size={14} />
                                            </button>
                                            <button className="icon-btn cancel" onClick={() => setConfirmDeleteId(null)}>
                                                <X size={14} />
                                            </button>
                                        </>
                                    ) : (
                                        <button className="icon-btn delete" onClick={() => setConfirmDeleteId(item.id)}>
                                            <Trash2 size={14} />
                                        </button>
                                    )}
                                </div>
                            </>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
}
