import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Store, MapPin, Phone, ChevronRight, ArrowLeft, LogIn } from "lucide-react";
import { fetchPublicRestaurants, estimateImage } from "../../services/api";
import "./CustomerPage.css";

export default function CustomerPage() {
    const navigate = useNavigate();
    const [restaurants, setRestaurants] = useState([]);
    const [loadingList, setLoadingList] = useState(true);
    const [selected, setSelected] = useState(null);

    // Scan state
    const [image, setImage] = useState(null);
    const [preview, setPreview] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [result, setResult] = useState(null);

    // Fetch restaurants on mount
    useEffect(() => {
        fetchPublicRestaurants()
            .then(setRestaurants)
            .catch(() => setRestaurants([]))
            .finally(() => setLoadingList(false));
    }, []);

    // Derived
    const itemCount = useMemo(() => {
        if (!result) return 0;
        return result.items.length;
    }, [result]);

    const handleBack = () => {
        setSelected(null);
        setImage(null);
        setPreview(null);
        setResult(null);
        setError(null);
    };

    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            setImage(file);
            setPreview(URL.createObjectURL(file));
            setResult(null);
            setError(null);
        }
    };

    const handleEstimate = async () => {
        if (!image || !selected) return;
        setLoading(true);
        setError(null);
        setResult(null);

        try {
            const data = await estimateImage(selected.id, image);
            setResult(data);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const handleScanAgain = () => {
        setImage(null);
        setPreview(null);
        setResult(null);
        setError(null);
    };

    // ── Restaurant List View ────────────────────────────────
    if (!selected) {
        return (
            <div className="customer-page">
                <div className="customer-top-bar">
                    <div className="customer-brand">
                        <h1>
                            Lauk<span>AI</span>
                        </h1>
                        <p>Scan your food, get the price</p>
                    </div>
                    <button
                        className="customer-login-btn"
                        onClick={() => navigate("/login")}
                    >
                        <LogIn size={16} /> Login
                    </button>
                </div>

                <h2 className="restaurant-list-title">Choose a Restaurant</h2>

                {loadingList ? (
                    <div className="customer-loading">Loading restaurants...</div>
                ) : restaurants.length === 0 ? (
                    <div className="empty-list">No restaurants available yet.</div>
                ) : (
                    <div className="restaurant-list">
                        {restaurants.map((r) => (
                            <div
                                key={r.id}
                                className="restaurant-card"
                                onClick={() => setSelected(r)}
                            >
                                <div className="restaurant-card-icon">
                                    <Store size={22} />
                                </div>
                                <div className="restaurant-card-info">
                                    <div className="restaurant-card-name">{r.name}</div>
                                    {r.address && (
                                        <div className="restaurant-card-detail">
                                            <MapPin size={12} /> {r.address}
                                        </div>
                                    )}
                                    {r.phone && (
                                        <div className="restaurant-card-detail">
                                            <Phone size={12} /> {r.phone}
                                        </div>
                                    )}
                                </div>
                                <ChevronRight size={20} className="restaurant-card-arrow" />
                            </div>
                        ))}
                    </div>
                )}
            </div>
        );
    }

    // ── Scan & Estimate View ────────────────────────────────
    return (
        <div className="customer-page">
            <div className="back-bar">
                <button className="back-btn" onClick={handleBack}>
                    <ArrowLeft size={20} />
                </button>
                <span className="back-restaurant-name">{selected.name}</span>
            </div>

            {/* Image Upload */}
            <div className="upload-section">
                <label className="upload-box" htmlFor="customer-file-input">
                    {preview ? (
                        <img src={preview} alt="Preview" className="preview-img" />
                    ) : (
                        <div className="upload-placeholder">
                            <span className="upload-icon">📷</span>
                            <p>Click to select an image</p>
                        </div>
                    )}
                    <input
                        id="customer-file-input"
                        type="file"
                        accept="image/*"
                        onChange={handleFileChange}
                        hidden
                    />
                </label>

                <button
                    className="detect-btn"
                    onClick={handleEstimate}
                    disabled={!image || loading}
                >
                    {loading ? "Estimating..." : "Estimate Price"}
                </button>
            </div>

            {error && <div className="error-box">{error}</div>}

            {/* Estimate Result */}
            {result && (
                <>
                    <div className="estimate-receipt">
                        <div className="estimate-header">
                            <h2>Price Estimate</h2>
                            <span className="estimate-count">{itemCount} items</span>
                        </div>

                        <div className="estimate-items">
                            {result.items.map((item, i) => (
                                <div key={i} className="estimate-row">
                                    <span
                                        className={`estimate-item-name ${!item.known ? "unpriced" : ""}`}
                                    >
                                        {item.known ? item.name : `${item.yolo_class} (unpriced)`}
                                    </span>
                                    <span
                                        className={`estimate-item-price ${!item.known ? "unpriced" : ""}`}
                                    >
                                        {item.known
                                            ? `RM ${item.price.toFixed(2)}`
                                            : "—"}
                                    </span>
                                </div>
                            ))}
                        </div>

                        <div className="estimate-total">
                            <span className="estimate-total-label">Estimated Total</span>
                            <span className="estimate-total-price">
                                RM {result.total.toFixed(2)}
                            </span>
                        </div>

                        {result.items.some((item) => !item.known) && (
                            <div className="estimate-note">
                                Some items could not be priced. The actual total may differ.
                            </div>
                        )}
                    </div>

                    <button className="scan-again-btn" onClick={handleScanAgain}>
                        Scan Another Tray
                    </button>
                </>
            )}
        </div>
    );
}
