import { useState, useEffect } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { fetchRestaurant, updateRestaurant } from "../../services/api";
import { Store, Save } from "lucide-react";

export default function RestaurantProfile() {
    const { user } = useAuth();
    const [profile, setProfile] = useState({ name: "", address: "", phone: "" });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState(null);
    const [success, setSuccess] = useState(false);

    useEffect(() => {
        (async () => {
            try {
                const data = await fetchRestaurant();
                setProfile({
                    name: data.name || "",
                    address: data.address || "",
                    phone: data.phone || "",
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
            const updated = await updateRestaurant(profile);
            setProfile({
                name: updated.name || "",
                address: updated.address || "",
                phone: updated.phone || "",
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

    if (loading) return <div className="settings-loading">Loading profile…</div>;

    return (
        <div className="settings-section">
            <div className="settings-section-header">
                <h3><Store size={18} /> Restaurant Profile</h3>
            </div>

            {error && <div className="settings-error">{error}</div>}
            {success && <div className="settings-success">Profile updated!</div>}

            <div className="settings-form">
                <label>
                    <span>Restaurant Name</span>
                    <input
                        type="text"
                        value={profile.name}
                        onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                        disabled={!isOwner}
                    />
                </label>
                <label>
                    <span>Address</span>
                    <input
                        type="text"
                        value={profile.address}
                        onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                        disabled={!isOwner}
                        placeholder="e.g. 123 Jalan Makan, KL"
                    />
                </label>
                <label>
                    <span>Phone</span>
                    <input
                        type="text"
                        value={profile.phone}
                        onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                        disabled={!isOwner}
                        placeholder="e.g. 012-345 6789"
                    />
                </label>
                {isOwner && (
                    <button className="settings-save-btn" onClick={handleSave} disabled={saving}>
                        <Save size={14} />
                        {saving ? "Saving…" : "Save Changes"}
                    </button>
                )}
            </div>
        </div>
    );
}
