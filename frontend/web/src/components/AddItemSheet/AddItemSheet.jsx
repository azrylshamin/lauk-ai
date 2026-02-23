import { useState, useEffect } from "react";
import { fetchMenuItems } from "../../services/api";
import "./AddItemSheet.css";

export default function AddItemSheet({ onSelect, onClose }) {
    const [menuItems, setMenuItems] = useState([]);
    const [search, setSearch] = useState("");
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Fetch menu on mount
    useEffect(() => {
        let cancelled = false;

        fetchMenuItems()
            .then((data) => {
                if (!cancelled) setMenuItems(data);
            })
            .catch((err) => {
                if (!cancelled) setError(err.message);
            })
            .finally(() => {
                if (!cancelled) setLoading(false);
            });

        return () => {
            cancelled = true;
        };
    }, []);

    const filtered = menuItems.filter(
        (item) =>
            item.name.toLowerCase().includes(search.toLowerCase()) ||
            item.yolo_class.toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div className="sheet-overlay" onClick={onClose}>
            <div className="sheet" onClick={(e) => e.stopPropagation()}>
                <div className="sheet-header">
                    <h3>Add Item</h3>
                    <button className="sheet-close" onClick={onClose}>
                        ✕
                    </button>
                </div>

                <div className="sheet-search">
                    <input
                        type="text"
                        placeholder="Search menu..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        autoFocus
                    />
                </div>

                {loading ? (
                    <div className="sheet-loading">Loading menu...</div>
                ) : error ? (
                    <div className="sheet-empty">Error: {error}</div>
                ) : filtered.length === 0 ? (
                    <div className="sheet-empty">No items found</div>
                ) : (
                    <div className="menu-grid">
                        {filtered.map((item) => (
                            <button
                                key={item.id}
                                className="menu-tile"
                                onClick={() => onSelect(item)}
                            >
                                <span className="menu-tile-name">{item.name}</span>
                                <span className="menu-tile-price">
                                    RM {parseFloat(item.price).toFixed(2)}
                                </span>
                            </button>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
