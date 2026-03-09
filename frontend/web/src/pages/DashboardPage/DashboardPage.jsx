import { useState, useEffect, useMemo } from "react";
import { Camera, ClipboardList, Settings, Store } from "lucide-react";
import { predictImage, assignMenuItem, saveBill, fetchRestaurant } from "../../services/api";
import { useAuth } from "../../contexts/AuthContext";
import Header from "../../components/Header/Header";
import StatsBar from "../../components/StatsBar/StatsBar";
import ImageUpload from "../../components/ImageUpload/ImageUpload";
import Receipt from "../../components/Receipt/Receipt";
import AddItemSheet from "../../components/AddItemSheet/AddItemSheet";
import SuccessToast from "../../components/SuccessToast/SuccessToast";
import HistoryTab from "../../components/HistoryTab/HistoryTab";
import SettingsTab from "../../components/SettingsTab/SettingsTab";
import "./DashboardPage.css";
import "./DashboardLayout.css"; // Responsive layout CSS

export default function DashboardPage() {
    const { user } = useAuth();
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

    // ── Tax settings ─────────────────────────────────────────
    const [taxSettings, setTaxSettings] = useState({
        sst_enabled: false, sst_rate: 0, sc_enabled: false, sc_rate: 0,
    });

    useEffect(() => {
        fetchRestaurant()
            .then((data) => setTaxSettings({
                sst_enabled: data.sst_enabled ?? false,
                sst_rate: parseFloat(data.sst_rate) || 0,
                sc_enabled: data.sc_enabled ?? false,
                sc_rate: parseFloat(data.sc_rate) || 0,
            }))
            .catch(() => {});
    }, []);

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

    const sstAmount = taxSettings.sst_enabled
        ? Math.round(total * taxSettings.sst_rate) / 100 : 0;
    const scAmount = taxSettings.sc_enabled
        ? Math.round(total * taxSettings.sc_rate) / 100 : 0;
    const grandTotal = Math.round((total + sstAmount + scAmount) * 100) / 100;

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
        <div className="dashboard-wrapper">
            {/* Sidebar / Bottom Navigation */}
            <nav className="dashboard-nav">
                {/* Desktop Branding (Hidden on mobile via flex layout logic/position) */}
                <div className="dashboard-brand" style={{ display: 'none' /* handled mostly by media queries but forcing structure here may need css tweak */ }}>
                    <h1>LaukAI</h1>
                    <p>Food Detection System</p>
                </div>
                {/* We use CSS media queries to show branding only in sidebar mode */}
                <style>{`
                  @media (min-width: 768px) {
                      .dashboard-brand { display: block !important; }
                  }
                `}</style>

                <button
                    className={`nav-item ${activeTab === "scan" ? "active" : ""}`}
                    onClick={() => setActiveTab("scan")}
                >
                    <Camera size={20} className="nav-icon" /> <span>Scan</span>
                </button>
                <button
                    className={`nav-item ${activeTab === "history" ? "active" : ""}`}
                    onClick={() => setActiveTab("history")}
                >
                    <ClipboardList size={20} className="nav-icon" /> <span>History</span>
                </button>
                <button
                    className={`nav-item ${activeTab === "settings" ? "active" : ""}`}
                    onClick={() => setActiveTab("settings")}
                >
                    <Settings size={20} className="nav-icon" /> <span>Settings</span>
                </button>
            </nav>

            {/* Main Content Area */}
            <main className="dashboard-content">
                <Header />

                {/* Only show Stats on Scan and History tabs for a cleaner settings view */}
                {activeTab !== "settings" && <StatsBar refreshKey={statsKey} />}

                <div className="tab-content-container">
                    {activeTab === "scan" && (
                        <div className="scan-layout">
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
                                    subtotal={total}
                                    sstAmount={sstAmount}
                                    scAmount={scAmount}
                                    grandTotal={grandTotal}
                                    sstRate={taxSettings.sst_rate}
                                    scRate={taxSettings.sc_rate}
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
                        </div>
                    )}

                    {activeTab === "history" && <HistoryTab key={statsKey} />}
                    {activeTab === "settings" && <SettingsTab />}
                </div>
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
