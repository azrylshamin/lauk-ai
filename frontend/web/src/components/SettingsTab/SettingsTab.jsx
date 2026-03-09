import MenuManager from "./MenuManager";
import RestaurantProfile from "./RestaurantProfile";
import TaxSettings from "./TaxSettings";
import EmployeeManager from "./EmployeeManager";
import "./SettingsTab.css";

export default function SettingsTab() {
    return (
        <div className="settings-tab">
            <MenuManager />
            <RestaurantProfile />
            <TaxSettings />
            <EmployeeManager />
        </div>
    );
}
