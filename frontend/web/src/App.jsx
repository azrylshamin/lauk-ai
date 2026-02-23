import { useState } from "react";
import "./App.css";

const API_URL = "http://localhost:3000";

function App() {
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState(null);
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [assigningClass, setAssigningClass] = useState(null);
  const [assignForm, setAssignForm] = useState({ name: "", price: "" });

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImage(file);
      setPreview(URL.createObjectURL(file));
      setResults(null);
      setError(null);
    }
  };

  const detectFood = async () => {
    if (!image) return;

    setLoading(true);
    setError(null);
    setResults(null);

    try {
      const formData = new FormData();
      formData.append("file", image);

      const res = await fetch(`${API_URL}/api/predict`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.detail || data.error || "Unknown error");
        return;
      }

      setResults(data);
    } catch (err) {
      setError(`Connection failed: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleAssign = async (yoloClass) => {
    const { name, price } = assignForm;
    if (!name.trim() || !price) return;

    try {
      const res = await fetch(`${API_URL}/api/menu-items`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          yolo_class: yoloClass,
          name: name.trim(),
          price: parseFloat(price),
        }),
      });

      if (!res.ok) {
        const data = await res.json();
        setError(data.error || "Failed to assign item");
        return;
      }

      // Re-scan after assigning
      setAssigningClass(null);
      setAssignForm({ name: "", price: "" });
      detectFood();
    } catch (err) {
      setError(`Assign failed: ${err.message}`);
    }
  };

  const checkHealth = async () => {
    try {
      const res = await fetch(`${API_URL}/api/health`);
      const data = await res.json();
      alert(JSON.stringify(data, null, 2));
    } catch (err) {
      alert(`Cannot reach backend: ${err.message}`);
    }
  };

  const hasUnknown = results?.items?.some((item) => !item.known);

  return (
    <div className="app">
      <header className="header">
        <h1>LaukAI</h1>
        <p className="subtitle">Food Detection &amp; Pricing</p>
        <button className="health-btn" onClick={checkHealth}>
          Check Health
        </button>
      </header>

      <main className="main">
        {/* Upload area */}
        <div className="upload-section">
          <label className="upload-box" htmlFor="file-input">
            {preview ? (
              <img src={preview} alt="Preview" className="preview-img" />
            ) : (
              <div className="upload-placeholder">
                <span className="upload-icon">📷</span>
                <p>Click to select an image</p>
              </div>
            )}
            <input
              id="file-input"
              type="file"
              accept="image/*"
              onChange={handleFileChange}
              hidden
            />
          </label>

          <button
            className="detect-btn"
            onClick={detectFood}
            disabled={!image || loading}
          >
            {loading ? "Detecting..." : "Detect Food"}
          </button>
        </div>

        {/* Error */}
        {error && <div className="error-box">{error}</div>}

        {/* Results — Itemised Receipt */}
        {results && (
          <div className="receipt">
            <div className="receipt-header">
              <h2>Order Summary</h2>
              <span className="item-count">{results.count} items</span>
            </div>

            {results.count === 0 ? (
              <p className="no-results">
                No food items detected. Try another image.
              </p>
            ) : (
              <>
                <div className="receipt-items">
                  {results.items.map((item, i) => (
                    <div
                      key={i}
                      className={`receipt-row ${!item.known ? "unknown" : ""}`}
                    >
                      <div className="receipt-row-left">
                        <span className="item-name">
                          {item.name}
                          {!item.known && (
                            <span className="unknown-badge">?</span>
                          )}
                        </span>
                        <span className="item-class">{item.yolo_class}</span>
                      </div>
                      <div className="receipt-row-right">
                        <span className="item-confidence">
                          {(item.confidence * 100).toFixed(0)}%
                        </span>
                        {item.known ? (
                          <span className="item-price">
                            RM {item.price.toFixed(2)}
                          </span>
                        ) : (
                          <button
                            className="assign-btn"
                            onClick={() => {
                              setAssigningClass(item.yolo_class);
                              setAssignForm({ name: "", price: "" });
                            }}
                          >
                            Assign
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>

                {/* Assign form for unknown items */}
                {assigningClass && (
                  <div className="assign-form">
                    <p className="assign-title">
                      Assign "<strong>{assigningClass}</strong>" to a menu item
                    </p>
                    <div className="assign-fields">
                      <input
                        type="text"
                        placeholder="Item name (e.g. Ayam)"
                        value={assignForm.name}
                        onChange={(e) =>
                          setAssignForm({ ...assignForm, name: e.target.value })
                        }
                      />
                      <input
                        type="number"
                        step="0.10"
                        min="0"
                        placeholder="Price (RM)"
                        value={assignForm.price}
                        onChange={(e) =>
                          setAssignForm({
                            ...assignForm,
                            price: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="assign-actions">
                      <button
                        className="assign-save"
                        onClick={() => handleAssign(assigningClass)}
                        disabled={!assignForm.name.trim() || !assignForm.price}
                      >
                        Save
                      </button>
                      <button
                        className="assign-cancel"
                        onClick={() => setAssigningClass(null)}
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}

                {/* Total */}
                <div className="receipt-total">
                  <span className="total-label">Total</span>
                  <span className="total-price">
                    RM {results.total.toFixed(2)}
                  </span>
                </div>

                {hasUnknown && (
                  <p className="unknown-hint">
                    Items marked with <span className="unknown-badge inline">?</span>{" "}
                    are not in the menu. Click "Assign" to add them.
                  </p>
                )}
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
