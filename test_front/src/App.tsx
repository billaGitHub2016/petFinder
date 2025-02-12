import {BrowserRouter as Router, Route, Routes} from "react-router-dom";
import Contract from "./pages/Contract";
import NaviBar from "./components/navi-bar";
import AdoptContracts from "@/pages/AdoptContracts.tsx";
import SignContract from "@/pages/SignContract.tsx";

function App() {
    return (
        <Router>
            <div className="bg-background">
                <NaviBar/>
                <Routes>
                    <Route path="/" element={<AdoptContracts/>}/>
                    <Route path="/createContract" element={<Contract/>}/>
                    <Route path="/signContract" element={<SignContract/>}/>
                </Routes>
            </div>
        </Router>
    );
}

export default App;
