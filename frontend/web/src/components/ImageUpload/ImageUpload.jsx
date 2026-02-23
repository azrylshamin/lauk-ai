import "./ImageUpload.css";

export default function ImageUpload({ preview, onFileChange, onDetect, loading, disabled }) {
    return (
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
                    onChange={onFileChange}
                    hidden
                />
            </label>

            <button
                className="detect-btn"
                onClick={onDetect}
                disabled={disabled || loading}
            >
                {loading ? "Detecting..." : "Detect Food"}
            </button>
        </div>
    );
}
