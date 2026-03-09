import { useState, useEffect } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { fetchRestaurant, updateRestaurant } from "../../services/api";
import { Percent, Save } from "lucide-react";

export default function TaxSettings() {
    const { user } = useAuth();
    const [settings, setSettings] = useState({
        sst_enabled: false,
        sst_rate: 6,
        sc_enabled: false,
        sc_rate: 10,
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState(null);
    const [success, setSuccess] = useState(false);

    useEffect(() => {
        (async () => {
            try {
                const data = await fetchRestaurant();
                setSettings({
                    sst_enabled: data.sst_enabled ?? false,
                    sst_rate: parseFloat(data.sst_rate) || 6,
                    sc_enabled: data.sc_enabled ?? false,
                    sc_rate: parseFloat(data.sc_rate) || 10,
                });
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        })();
    }, []);

    const handleSave = async () => {
        setSaving(true);
        setError(null);
        setSuccess(false);
        try {
            const updated = await updateRestaurant(settings);
            setSettings({
                sst_enabled: updated.sst_enabled ?? false,
                sst_rate: parseFloat(updated.sst_rate) || 6,
                sc_enabled: updated.sc_enabled ?? false,
                sc_rate: parseFloat(updated.sc_rate) || 10,
            });
            setSuccess(true);
            setTimeout(() => setSuccess(false), 2500);
        } catch (err) {
            setError(err.message);
        } finally {
            setSaving(false);
        }
    };

    const isOwner = user?.role === "owner";

    if (loading) return <div className="settings-loading">Loading tax settings...</div>;

    return (
        <div className="settings-section">
            <div className="settings-section-header">
                <h3><Percent size={18} /> Tax & Charges</h3>
            </div>

            {error && <div className="settings-error">{error}</div>}
            {success && <div className="settings-success">Tax settings updated!</div>}

            <div className="settings-form">
                <div className="tax-row">
                    <label className="toggle-switch">
                        <input
                            type="checkbox"
                            checked={settings.sst_enabled}
                            onChange={(e) => setSettings({ ...settings, sst_enabled: e.target.checked })}
                            disabled={!isOwner}
                        />
                        <span className="toggle-slider" />
                    </label>
                    <span className="tax-label">SST</span>
                    <div className="tax-rate-input">
                        <input
                            type="number"
                            min="0"
                            max="100"
                            step="0.5"
                            value={settings.sst_rate}
                            onChange={(e) => setSettings({ ...settings, sst_rate: e.target.value })}
                            disabled={!isOwner || !settings.sst_enabled}
                        />
                        <span className="tax-rate-suffix">%</span>
                    </div>
                </div>

                <div className="tax-row">
                    <label className="toggle-switch">
                        <input
                            type="checkbox"
                            checked={settings.sc_enabled}
                            onChange={(e) => setSettings({ ...settings, sc_enabled: e.target.checked })}
                            disabled={!isOwner}
                        />
                        <span className="toggle-slider" />
                    </label>
                    <span className="tax-label">Service Charge</span>
                    <div className="tax-rate-input">
                        <input
                            type="number"
                            min="0"
                            max="100"
                            step="0.5"
                            value={settings.sc_rate}
                            onChange={(e) => setSettings({ ...settings, sc_rate: e.target.value })}
                            disabled={!isOwner || !settings.sc_enabled}
                        />
                        <span className="tax-rate-suffix">%</span>
                    </div>
                </div>

                {isOwner && (
                    <button className="settings-save-btn" onClick={handleSave} disabled={saving}>
                        <Save size={14} />
                        {saving ? "Saving..." : "Save Changes"}
                    </button>
                )}
            </div>
        </div>
    );
}
