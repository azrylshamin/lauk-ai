import { checkHealth as checkHealthApi } from "../../services/api";
import "./Header.css";

export default function Header() {
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
            <h1>LaukAI</h1>
            <p className="subtitle">Food Detection &amp; Pricing</p>
            <button className="health-btn" onClick={handleHealthCheck}>
                Check Health
            </button>
        </header>
    );
}
