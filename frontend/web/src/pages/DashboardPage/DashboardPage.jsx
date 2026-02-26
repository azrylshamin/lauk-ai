import { useState, useMemo } from "react";
import { Camera, ClipboardList } from "lucide-react";
import { predictImage, assignMenuItem, saveBill } from "../../services/api";
import Header from "../../components/Header/Header";
import StatsBar from "../../components/StatsBar/StatsBar";
import ImageUpload from "../../components/ImageUpload/ImageUpload";
import Receipt from "../../components/Receipt/Receipt";
import AddItemSheet from "../../components/AddItemSheet/AddItemSheet";
import SuccessToast from "../../components/SuccessToast/SuccessToast";
import HistoryTab from "../../components/HistoryTab/HistoryTab";
import "./DashboardPage.css";

export default function DashboardPage() {
    const [activeTab, setActiveTab] = useState("scan");
    const [statsKey, setStatsKey] = useState(0);

    // ── Scan state ──────────────────────────────────────────────
    const [image, setImage] = useState(null);
    const [preview, setPreview] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const [editableItems, setEditableItems] = useState(null);
    const [confirmed, setConfirmed] = useState(false);
    const [confirming, setConfirming] = useState(false);

    const [showAddSheet, setShowAddSheet] = useState(false);
    const [assigningClass, setAssigningClass] = useState(null);

    // ── Derived ────────────────────────────────────────────────
    const total = useMemo(() => {
        if (!editableItems) return 0;
        return editableItems.reduce(
            (sum, item) => (item.known && item.price != null ? sum + item.price * item.quantity : sum),
            0
        );
    }, [editableItems]);

    const itemCount = useMemo(() => {
        if (!editableItems) return 0;
        return editableItems.reduce((sum, item) => sum + item.quantity, 0);
    }, [editableItems]);

    const hasUnknown = editableItems?.some((item) => !item.known);

    // ── Handlers ───────────────────────────────────────────────
    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            setImage(file);
            setPreview(URL.createObjectURL(file));
            setEditableItems(null);
            setError(null);
            setConfirmed(false);
        }
    };

    const handleDetect = async () => {
        if (!image) return;
        setLoading(true);
        setError(null);
        setEditableItems(null);
        setConfirmed(false);

        try {
            const data = await predictImage(image);
            const items = data.items.map((item, i) => ({
                ...item,
                id: `det-${Date.now()}-${i}`,
                quantity: 1,
            }));
            setEditableItems(items);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const updateQuantity = (id, delta) => {
        setEditableItems((prev) =>
            prev.map((item) =>
                item.id === id ? { ...item, quantity: Math.max(1, item.quantity + delta) } : item
            )
        );
    };

    const removeItem = (id) => {
        setEditableItems((prev) => prev.filter((item) => item.id !== id));
    };

    const handleAssignSave = async (yoloClass, name, price) => {
        try {
            const created = await assignMenuItem(yoloClass, name, price);
            setEditableItems((prev) =>
                prev.map((item) =>
                    item.yolo_class === yoloClass
                        ? { ...item, name: created.name, price: parseFloat(created.price), known: true, menu_item_id: created.id }
                        : item
                )
            );
            setAssigningClass(null);
        } catch (err) {
            setError(err.message);
        }
    };

    const handleAddMenuItem = (menuItem) => {
        setEditableItems((prev) => {
            const existing = prev.find((item) => item.known && item.yolo_class === menuItem.yolo_class);
            if (existing) {
                return prev.map((item) =>
                    item.id === existing.id ? { ...item, quantity: item.quantity + 1 } : item
                );
            }
            return [
                ...prev,
                {
                    id: `add-${Date.now()}-${menuItem.id}`,
                    name: menuItem.name,
                    yolo_class: menuItem.yolo_class,
                    price: parseFloat(menuItem.price),
                    confidence: null,
                    known: true,
                    quantity: 1,
                    menu_item_id: menuItem.id,
                },
            ];
        });
        setShowAddSheet(false);
    };

    const handleConfirm = async () => {
        if (!editableItems || editableItems.length === 0) return;
        setConfirming(true);
        setError(null);

        try {
            await saveBill(editableItems, total);
            setConfirmed(true);
            setStatsKey((k) => k + 1); // refresh stats
            setTimeout(() => {
                setEditableItems(null);
                setConfirmed(false);
                setImage(null);
                setPreview(null);
            }, 2500);
        } catch (err) {
            setError(err.message);
        } finally {
            setConfirming(false);
        }
    };

    // ── Render ─────────────────────────────────────────────────
    return (
        <div className="app">
            <Header />
            <StatsBar refreshKey={statsKey} />

            {/* Tab Bar */}
            <div className="tab-bar">
                <button
                    className={`tab-btn ${activeTab === "scan" ? "active" : ""}`}
                    onClick={() => setActiveTab("scan")}
                >
                    <Camera size={16} /> Scan
                </button>
                <button
                    className={`tab-btn ${activeTab === "history" ? "active" : ""}`}
                    onClick={() => setActiveTab("history")}
                >
                    <ClipboardList size={16} /> History
                </button>
            </div>

            <main>
                {activeTab === "scan" && (
                    <>
                        <ImageUpload
                            preview={preview}
                            onFileChange={handleFileChange}
                            onDetect={handleDetect}
                            loading={loading}
                            disabled={!image}
                        />

                        {error && <div className="error-box">{error}</div>}
                        {confirmed && <SuccessToast />}

                        {editableItems && !confirmed && (
                            <Receipt
                                items={editableItems}
                                itemCount={itemCount}
                                total={total}
                                hasUnknown={hasUnknown}
                                confirming={confirming}
                                assigningClass={assigningClass}
                                onUpdateQty={updateQuantity}
                                onRemove={removeItem}
                                onStartAssign={setAssigningClass}
                                onAssignSave={handleAssignSave}
                                onAssignCancel={() => setAssigningClass(null)}
                                onAddItem={() => setShowAddSheet(true)}
                                onConfirm={handleConfirm}
                            />
                        )}
                    </>
                )}

                {activeTab === "history" && <HistoryTab key={statsKey} />}
            </main>

            {showAddSheet && (
                <AddItemSheet
                    onSelect={handleAddMenuItem}
                    onClose={() => setShowAddSheet(false)}
                />
            )}
        </div>
    );
}
