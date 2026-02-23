import "./SuccessToast.css";

export default function SuccessToast({ message = "Bill saved successfully!" }) {
    return (
        <div className="success-toast">
            <span className="success-icon">✓</span>
            {message}
        </div>
    );
}
