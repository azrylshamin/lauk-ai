import { useAuth } from "../../contexts/AuthContext";
import { checkHealth as checkHealthApi } from "../../services/api";
import "./Header.css";

export default function Header() {
    const { user, logout } = useAuth();

    const handleHealthCheck = async () => {
        try {
            const data = await checkHealthApi();
            alert(JSON.stringify(data, null, 2));
        } catch (err) {
            alert(`Cannot reach backend: ${err.message}`);
        }
    };

    return (
        <header className="header">
            <div className="header-top">
                <div className="header-brand">
                    <h1>LaukAI</h1>
                    <p className="subtitle">Food Detection &amp; Pricing</p>
                </div>
                {user && (
                    <div className="header-user">
                        <span className="restaurant-name">{user.restaurantName}</span>
                        <button className="logout-btn" onClick={logout}>
                            Sign Out
                        </button>
                    </div>
                )}
            </div>
            <button className="health-btn" onClick={handleHealthCheck}>
                Check Health
            </button>
        </header>
    );
}
