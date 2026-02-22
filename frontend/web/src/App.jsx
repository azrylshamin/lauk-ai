import { useState } from "react";
import "./App.css";

const API_URL = "http://localhost:3000";

function App() {
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState(null);
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

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

  const checkHealth = async () => {
    try {
      const res = await fetch(`${API_URL}/api/health`);
      const data = await res.json();
      alert(JSON.stringify(data, null, 2));
    } catch (err) {
      alert(`Cannot reach backend: ${err.message}`);
    }
  };

  return (
    <div className="app">
      <header className="header">
        <h1>LaukAI</h1>
        <p className="subtitle">Food Detection Demo</p>
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

        {/* Results */}
        {results && (
          <div className="results">
            <h2>Detected Items ({results.count})</h2>

            {results.count === 0 ? (
              <p className="no-results">No food items detected. Try another image.</p>
            ) : (
              <div className="detection-list">
                {results.detections.map((det, i) => (
                  <div key={i} className="detection-card">
                    <span className="class-name">{det.class}</span>
                    <span className="confidence">
                      {(det.confidence * 100).toFixed(1)}%
                    </span>
                  </div>
                ))}
              </div>
            )}

            <pre className="raw-json">
              {JSON.stringify(results, null, 2)}
            </pre>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
