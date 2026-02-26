import { useState, useEffect } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { fetchEmployees, inviteEmployee, removeEmployee } from "../../services/api";
import { UserPlus, Trash2, Check, X, Shield, User } from "lucide-react";

export default function EmployeeManager() {
    const { user } = useAuth();
    const [employees, setEmployees] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [showInvite, setShowInvite] = useState(false);
    const [inviteFields, setInviteFields] = useState({ name: "", email: "", password: "" });
    const [saving, setSaving] = useState(false);
    const [confirmDeleteId, setConfirmDeleteId] = useState(null);

    const isOwner = user?.role === "owner";

    useEffect(() => {
        (async () => {
            try {
                const data = await fetchEmployees();
                setEmployees(data);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        })();
    }, []);

    const handleInvite = async () => {
        if (!inviteFields.name || !inviteFields.email || !inviteFields.password) return;
        setSaving(true);
        setError(null);
        try {
            const created = await inviteEmployee(
                inviteFields.name,
                inviteFields.email,
                inviteFields.password
            );
            setEmployees((prev) => [...prev, created]);
            setInviteFields({ name: "", email: "", password: "" });
            setShowInvite(false);
        } catch (err) {
            setError(err.message);
        } finally {
            setSaving(false);
        }
    };

    const handleRemove = async (id) => {
        try {
            await removeEmployee(id);
            setEmployees((prev) => prev.filter((e) => e.id !== id));
            setConfirmDeleteId(null);
        } catch (err) {
            setError(err.message);
        }
    };

    if (!isOwner) {
        return (
            <div className="settings-section">
                <div className="settings-section-header">
                    <h3>Employees</h3>
                </div>
                <p className="settings-empty">Only the restaurant owner can manage employees.</p>
            </div>
        );
    }

    if (loading) return <div className="settings-loading">Loading employees…</div>;

    return (
        <div className="settings-section">
            <div className="settings-section-header">
                <h3>Employees</h3>
                <button
                    className="settings-add-btn"
                    onClick={() => setShowInvite(!showInvite)}
                >
                    {showInvite ? <X size={14} /> : <UserPlus size={14} />}
                    {showInvite ? "Cancel" : "Add Employee"}
                </button>
            </div>

            {error && <div className="settings-error">{error}</div>}

            {/* Invite form */}
            {showInvite && (
                <div className="settings-add-form">
                    <input
                        type="text"
                        placeholder="Full Name"
                        value={inviteFields.name}
                        onChange={(e) => setInviteFields({ ...inviteFields, name: e.target.value })}
                    />
                    <input
                        type="email"
                        placeholder="Email"
                        value={inviteFields.email}
                        onChange={(e) => setInviteFields({ ...inviteFields, email: e.target.value })}
                    />
                    <input
                        type="password"
                        placeholder="Temporary Password"
                        value={inviteFields.password}
                        onChange={(e) => setInviteFields({ ...inviteFields, password: e.target.value })}
                    />
                    <button className="settings-save-btn" onClick={handleInvite} disabled={saving}>
                        {saving ? "Inviting…" : "Send Invite"}
                    </button>
                </div>
            )}

            {/* Employee list */}
            <div className="settings-list">
                {employees.length === 0 && <p className="settings-empty">No employees yet.</p>}
                {employees.map((emp) => (
                    <div key={emp.id} className="settings-card">
                        <div className="settings-card-info">
                            <span className="card-name">
                                {emp.role === "owner" ? <Shield size={13} /> : <User size={13} />}
                                {emp.name}
                            </span>
                            <span className="card-class">{emp.email}</span>
                            <span className={`role-badge ${emp.role}`}>{emp.role}</span>
                        </div>
                        <div className="settings-card-actions">
                            {emp.role !== "owner" && (
                                <>
                                    {confirmDeleteId === emp.id ? (
                                        <>
                                            <button className="icon-btn delete confirm" onClick={() => handleRemove(emp.id)}>
                                                <Check size={14} />
                                            </button>
                                            <button className="icon-btn cancel" onClick={() => setConfirmDeleteId(null)}>
                                                <X size={14} />
                                            </button>
                                        </>
                                    ) : (
                                        <button className="icon-btn delete" onClick={() => setConfirmDeleteId(emp.id)}>
                                            <Trash2 size={14} />
                                        </button>
                                    )}
                                </>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
